
/*****************************************************************
	In the C-programs, we use EIF_OBJ and char * to indicate 
direct(also called raw or unprotected) address; use EIF_REFERENCE
to indicate indirect(also called Eiffel or protected) address.
*****************************************************************/

#include "net.h"
#include "curextern.h"
#define tSTOP_GC
#ifdef SIGPIPE
#define SIGNAL
#endif

#define ONLY_CABIN

void make_server(config_file)
char *config_file;
{


	int tmp_int;


	/* First, initialize global variables */

#ifdef STOP_GC
	gc_stop();
#endif

	setbuf(stdout, 0);
	setbuf(stderr, 0);

	FD_ZERO(&_concur_mask);
	_concur_mask_limit.low = FD_SETSIZE + 2;
	_concur_mask_limit.up = -1;

	_concur_blk_cli_list = NULL;
	_concur_end_of_blk_cli_list = NULL;
	_concur_blk_cli_list_count = 0;



	_concur_call_stack.info = NULL;
	_concur_call_stack.size = 0;
	_concur_call_stack.used = 0;

	_concur_scoop_dog = NULL;

	_concur_child_list = (CHILD *)NULL;
	_concur_end_of_child_list = (CHILD *)NULL;
	_concur_child_list_count = 0;

	_concur_cli_list = (CLIENT *)NULL;
	_concur_end_of_cli_list = (CLIENT *)NULL;
	_concur_cli_list_count = 0;
	
	_concur_ser_list = (SERVER *)NULL;
	_concur_end_of_ser_list = (SERVER *)NULL;
	_concur_ser_list_count = 0;

/*
	_concur_req_list = (REQUEST *)NULL;
	_concur_end_of_req_list = (REQUEST *)NULL;
	_concur_req_list_count = 0;
*/

	_concur_paras_size = constant_max_para_num;
	_concur_paras = (PARAMETER *)(malloc(_concur_paras_size * sizeof(PARAMETER))); 
	valid_memory(_concur_paras);
	for(tmp_int=0; tmp_int<_concur_paras_size; tmp_int++) 
		_concur_paras[tmp_int].str_len = 0;

	_concur_ref_table = (REF_TABLE_NODE *)NULL;
	_concur_exported_obj_list = (EXPORTED_OBJ_LIST_NODE *)NULL;
	_concur_imported_obj_tab = (IMPORTED_OBJ_TABLE_NODE *)NULL;

	_concur_server_list_released = 0;
	_concur_current_client_reserved = 0;
	_concur_terminatable = 1;
	_concur_exception_has_happened = 0;
	_concur_crash_info[0] = '\0';
	_concur_error_msg[0] = '\0';

	c_get_usrname();
	/* get current user's name into "_concur_user_name" */

	c_get_host_name();
	/* get local host's name into "_concur_host_name" */
	
	_concur_pid = c_get_pid();

#ifdef SIGNAL
#ifdef SIGPIPE
	signal(SIGPIPE, def_res);
#else
#endif
#endif

	if (_concur_parent) {
		set_mask(_concur_parent->sock);
	}
	_concur_sock = c_concur_make_server(_concur_pid);
	set_mask(_concur_sock);
	for(; _concur_sock < 0; ) {
		_concur_pid = _concur_pid + constant_port_skip;
		if (_concur_pid > constant_max_port ) {
			_concur_pid = _concur_pid % constant_port_model + constant_min_port;
		}
		_concur_sock = c_concur_make_server(_concur_pid);
	}
	c_concur_set_non_blocking(_concur_sock);
		
	con_make(config_file);
	/* read the information in configure file */

	c_reset_timer();

	return;
}

/*-----------------------------------------------------------------------*/
/*                                                                       */
/*                            Utilities                                  */
/*                                                                       */
/*-----------------------------------------------------------------------*/

EIF_BOOLEAN on_same_processor(s1, s2)
EIF_OBJ s1;
EIF_OBJ s2;
{
/* is the two separate objects on the same processor? */
	EIF_INTEGER so_id;
	EIF_POINTER str1, str2;
	EIF_INTEGER pid1, pid2;
	
	so_id = eif_type_id("SEP_OBJ");
	str1 =(eif_strtoc)(eif_field((s1), "hostname", EIF_REFERENCE));
	str2 =(eif_strtoc)(eif_field((s2), "hostname", EIF_REFERENCE));
	pid1 =eif_field((s1), "pid", EIF_INTEGER);
	pid2 =eif_field((s2), "pid", EIF_INTEGER);

	return !memcmp(str1, str2, strlen(str1)) && pid1 == pid2;
}

EIF_BOOLEAN on_local_processor(s1)
EIF_OBJ s1;
{
/* is the separate object on the local processor? */
	EIF_INTEGER so_id;
	EIF_POINTER str1;
	EIF_INTEGER pid1;
	
	if (!s1) {
		sprintf(crash_info, "    Try to apply feature/attribute to Void separate object.");
		c_raise_concur_exception(exception_void_separate_object);
	}
	so_id = eif_type_id("SEP_OBJ");
	str1 =(eif_strtoc)(eif_field((s1), "hostname", EIF_REFERENCE));
	pid1 =eif_field((s1), "pid", EIF_INTEGER);
#ifdef SEP_OBJ
	if (so_id <= 0 || !str1 || pid1<=0) {
		sprintf(crash_info, "    %d How can type_id(SEP_OBJ) = %d and hostname=%s, pid=%d!", _concur_pid, so_id, str1==NULL?"NULL":str1, pid1);
		c_raise_concur_exception(exception_sep_obj_not_visible);
	}
#endif

	return !memcmp(str1, _concur_hostname, strlen(str1)) && pid1 == _concur_pid;
}


CONNECTION  *setup_connection(hostn, port)
char *hostn;
EIF_INTEGER port;
{
/* used to create an proxy(a C-structure) which does not
 * require DISPOSE. Such a proxy is only used by run-time. 
 * It represents just a network connection and keeps some useful information.
*/

	CONNECTION *ret;

	EIF_INTEGER sock;

	if (port < 0 || !hostn) 
		return NULL;
	else {
		ret = (CONNECTION *)malloc(sizeof(CONNECTION));
		valid_memory(ret);
		strcpy(ret->hostname, hostn);
		ret->pid = port;
		ret->count = 0;
		ret->reservation = -1;
		ret->sock = c_concur_make_client(port, hostn);
		return ret;
	}
}


EIF_OBJ  create_child() {
/* used to create an proxy for a separate child Eiffel Object;
 * and return direct(unprotected) address. 
*/
/* At the time, we know nothing about the separate child, 
 * we can't insert a node for the separate child into CHILD LIST, 
 * we can't insert a node for the separate child into IMPORTED OBJECT TABLE
 * neither, so we can't call "create_sep_obj" to create a SEP_OBJ
 * proxy for the separate object.
 * We will insert nodes into these lists for the separate child
 * in "wait_sep_child_obj".
*/
	EIF_REFERENCE ret;
	EIF_INTEGER sep_obj_id;
	EIF_PROC c_make_without_connection;

	sep_obj_id = eif_type_id("SEP_OBJ");
	c_make_without_connection = eif_proc("make_without_connection", sep_obj_id);
#ifdef SEP_OBJ
	if (sep_obj_id < 0 || !c_make_without_connection) {
		sprintf(crash_info, "    %d How can type_id(SEP_OBJ) = %d and make_without_connection = %x!", _concur_pid, sep_obj_id, c_make_without_connection);
		c_raise_concur_exception(exception_sep_obj_not_visible);
	}
#endif
	ret = eif_create(sep_obj_id);
	(c_make_without_connection)(eif_access(ret), -1);

	return eif_wean(ret);
		
}

EIF_OBJ  create_sep_obj(hostn, port, o_id)
char *hostn;
EIF_INTEGER port;
EIF_INTEGER o_id;
{
/* return direct address. */
/* used to create an SEP_OBJ proxy  for separate object identified by
 * triple: <*hostn, port, o_id>.
 * It works in the following way:
 * o to decide is the object has been imported before or not.
 * o if imported before, just return the existing proxy id;
 * o otherwise, create an Eiffel object for it and return the object's OID(proxy ID),
 *   and REGISTER the object to the corresponding separate processor.
 * In the above procession, we also distinguish if the separate object is originally
 * located on the local processor or not.
*/
	EIF_REFERENCE ret;
	char * host_obj;
	EIF_INTEGER sep_obj_id;
	EIF_PROC c_make_without_connection, c_make, c_set_host_port, c_set_sock, c_set_proxy_id;


	EIF_INTEGER command_bak;
	EIF_INTEGER para_num_bak;
	PARAMETER *paras_bak;
	EIF_INTEGER paras_size_bak;
	EIF_REFERENCE my_str;

	EIF_INTEGER proxy_id;

	EIF_INTEGER sock;


	if (port < 0 || o_id < 0) 
		return NULL;
	else {
		proxy_id = get_proxy_oid_of_inported_object(hostn, port, o_id);
		if (proxy_id) {
		/* The object has been imported before(exist in IMPORTED OBJECT TABLE)*/
#ifdef nDISP_LIST
printf("******** The object(%s, %d, %d) has been imported before.!\n", hostn, port, o_id);
/*print_ref_table_and_exported_object();*/
#endif
			return eif_id_object(proxy_id); 
			/* return the unprotected address of the proxy */
		}
		
		/* Now, the separate object has never been imported before,
		 * so we create a SEP_OBJ for it, and insert the SEP_OBJ proxy's 
		 * OID into IMPORTED OBJECT TABLE for late use; then do something
		 * depend on if the imported object is a local object or an 
		 * object on another processor.
		*/
		sep_obj_id = eif_type_id("SEP_OBJ");
#ifdef SEP_OBJ
	if (sep_obj_id <= 0) {
		sprintf(crash_info, "    %d How can type_id(SEP_OBJ) = %d !", _concur_pid, sep_obj_id);
		c_raise_concur_exception(exception_sep_obj_not_visible);
	}
#endif
		ret = eif_create(sep_obj_id);
		proxy_id = eif_general_object_id(ret); /* register an OID first */
		insert_into_imported_object_table(hostn, port, o_id, proxy_id);		
		/* record the separate object's information in IMPORTED OBJECT TABLE */

		c_make_without_connection = eif_proc("make_without_connection", sep_obj_id);
		c_make = eif_proc("make", sep_obj_id);	
		c_set_host_port = eif_proc("set_host_port", sep_obj_id);
		c_set_sock = eif_proc("set_sock", sep_obj_id);
		c_set_proxy_id = eif_proc("set_proxy_id", sep_obj_id);
		(c_set_proxy_id)(eif_access(ret), proxy_id);
		host_obj = makestr(hostn, strlen(hostn));
		my_str = henter(host_obj);	/* protect the string in hector */
		if (!memcmp(hostn, _concur_hostname, strlen(hostn)) && port == _concur_pid ) {
		/* the object is actually a local object */
			(c_make_without_connection)(eif_access(ret), o_id);
			(c_set_host_port)(eif_access(ret), eif_access(my_str), port);
			/* initialize the SEP_OBJ proxy. At this time, its sock is negative. */
			if (exist_in_server_list(hostn, port))  {
				sock = get_sock_from_server_list(hostn, port);
				(c_set_sock)(eif_access(ret), sock);
			}
			else {
			/* insert a node into SERVER LIST */
				sock = eif_field(eif_access(ret), "sock", EIF_INTEGER);
				add_to_server_list(hostn, port, sock);
			}
			host_obj = eif_wean(my_str); /* free the string from hector */
			change_ref_table_and_exported_obj_list(_concur_hostname, _concur_pid, o_id, 1); 
			/* The local object is inported from the local processor itself,
			 * so we don't send REGISTER request, we directly  change the 
			 * REFERENCE TABLE and EXPORTED OBJECT LIST.
			*/
			return eif_wean(ret); 
			/* return direct address and free the object from hector */
		}
		else {
		/* the object resides on another processor */
			if (exist_in_server_list(hostn, port)) {
				(c_make_without_connection)(eif_access(ret), o_id);
				(c_set_host_port)(eif_access(ret), eif_access(my_str), port);
				sock = get_sock_from_server_list(hostn, port);
				(c_set_sock)(eif_access(ret), sock);
			}
			else {
				(c_make)(eif_access(ret), eif_access(my_str), port, o_id);	
				sock = eif_field(eif_access(ret), "sock", EIF_INTEGER);
				add_to_server_list(hostn, port, sock);
			}
			
			/* The following is to REGISTER the imported object on the 
			 * corresponding processor.
			*/
			/* Because the function may be called in the process of
			 * filling in the PARAMETER ARRAY, so we 
			 * should keep the environment for the PARAMETER ARRAY, and 
			 * restore the environment when we finish at sending the REGISTER 
			 * request.
			*/
			command_bak = _concur_command; 
			para_num_bak = _concur_para_num;
			paras_bak = _concur_paras;
			paras_size_bak = _concur_paras_size;
		
			_concur_paras = NULL;
			_concur_paras_size = 0L;
			adjust_parameter_array(3);
			
			_concur_paras[0].type = String_type;
			set_str_val_into_parameter(_concur_paras, _concur_hostname);

			_concur_paras[1].type = Integer_type;
			_concur_paras[1].uval.int_val = _concur_pid;

			_concur_paras[2].type = Integer_type;
			_concur_paras[2].uval.int_val = o_id; 

			_concur_command = constant_register;
			_concur_para_num = 3;

			send_command(sock);

			get_cmd_data(sock);
			if (_concur_command != constant_register_ack) {
				add_nl;
				sprintf(crash_info, CURIMPERR1, command_text(_concur_command));
				c_raise_concur_exception(exception_unexpected_request); 
			}

			/* Now, free the new allocated parameter array and restore
			 * the environment of the original PARAMETER ARRAY.
			*/
			free_parameter_array(_concur_paras, _concur_paras_size);

			_concur_command = command_bak;
			_concur_paras = paras_bak;
			_concur_paras_size = paras_size_bak;
			_concur_para_num = para_num_bak;
			
			host_obj = eif_wean(my_str); /* free the string from hector */ 
			return eif_wean(ret);
			/* return direct address and free the object from hector */
		}
	}
		
}

EIF_OBJ clone_sep_obj_proxy(obj)
EIF_OBJ obj;
{
/* return direct address */
	EIF_POINTER host_in_c;
	char * obj_ptr;
	EIF_OBJ ret;

	EIF_REFERENCE protected_obj;
	
	if (obj == NULL) {
		return NULL;
	}
	else {
/*
		protected_obj = henter(obj);
*/
		
		ret = create_sep_obj(get_c_format_of_eif_string(obj, "hostname"), eif_field(obj, "pid", EIF_INTEGER), eif_field(obj, "oid", EIF_INTEGER));
		return ret;
	}
}


EIF_BOOLEAN reserve_sep_obj(sep_obj)
EIF_OBJ sep_obj;
{
/* to get exclusive access to a separate object. 
 * if we successly reserve the separate object, return 0; otherwise return 1.
 * After successfully reserving the separate object, the separate object 
 * will only be accessed by the
 * current processor until it's freed by "free_sep_obj".
*/
	char *hostn;
	EIF_INTEGER sock;
	EIF_INTEGER ret;
	int timeout, timeoutm;

	if ((sep_obj) == NULL || on_local_processor(sep_obj)) {
		return 0;
	}
	hostn = get_c_format_of_eif_string((sep_obj), "hostname");
	_concur_command = constant_reserve;
	_concur_para_num = 0;
	sock = eif_field((sep_obj), "sock", EIF_INTEGER);
	send_command(sock);
	get_cmd_data(sock);
	if (_concur_command == constant_reserve_ack) 	
		return 0;
	else
	if (_concur_command == constant_reserve_fail) {	
		c_concur_select(ret, 1, NULL, NULL, NULL, 0, (_concur_pid % 2) * 10000 + (_concur_pid % 10) * 4000);
		return 1;
	}
	else {
		add_nl;
		sprintf(crash_info+strlen(crash_info), CURAPPERR1, command_text(_concur_command));
		c_raise_concur_exception(exception_unexpected_request);
	}
} 

void free_sep_obj(sep_obj)
EIF_OBJ sep_obj;
{
/* to release the exclusive access from a separate object. 
 * after the function, the separate object is free to be accessed by other
 * separate object.
*/
	char *hostn;
	EIF_INTEGER sock;

	if ((sep_obj) == NULL || on_local_processor(sep_obj))
		return;
	hostn = get_c_format_of_eif_string((sep_obj), "hostname");
	_concur_command = constant_end_of_request;
	_concur_para_num = 0;
	sock = eif_field((sep_obj), "sock", EIF_INTEGER);
	send_command(sock);

	return;
}

char *command_text(cmd)
EIF_INTEGER cmd;
{
/* given a request's code, return the name of the request in text. */
	switch (cmd) {
	case constant_reserve:
		strcpy(_concur_command_text, " RESERVE_SEP_OBJ ");
		return _concur_command_text;
	case constant_reserve_ack:
		strcpy(_concur_command_text, " ACKNOWLEDGE_TO_RESERVE_SEP_OBJ ");
		return _concur_command_text;
	case constant_reserve_fail:
		strcpy(_concur_command_text, " REJECT_TO_RESERVE_SEP_OBJ ");
		return _concur_command_text;
	case constant_register_first_from_parent:
		strcpy(_concur_command_text, " REGISTER_FIRST_FROM_PARENT "); 
		return _concur_command_text;
	case constant_register:
		strcpy(_concur_command_text, " REGISTER "); 
		return _concur_command_text;
	case constant_register_ack:
		strcpy(_concur_command_text, " REGISTER_ACK "); 
		return _concur_command_text;
	case constant_register_ack_with_root_oid:
		strcpy(_concur_command_text, " REGISTER_ACK_WITH_ROOT_OID "); 
		return _concur_command_text;
	case constant_unregister:
		strcpy(_concur_command_text, " UNREGISTER "); 
		return _concur_command_text;
	case constant_release:
		strcpy(_concur_command_text, " RELEASE "); 
		return _concur_command_text;
	case constant_query_result:
		strcpy(_concur_command_text, " QUERY_RESULT "); 
		return _concur_command_text;
	case constant_ack_for_procedure:
		strcpy(_concur_command_text, " ACKNOWLEDGE_FOR_PROCEDURE "); 
		return _concur_command_text;
	case constant_middle_result_of_importation:
		strcpy(_concur_command_text, " MIDDLE_RESULT_OF_IMPORTATION "); 
		return _concur_command_text;
	case constant_release_sep_obj:
		strcpy(_concur_command_text, " RELEASE_SEP_OBJ "); 
		return _concur_command_text;
	case constant_release_processor:
		strcpy(_concur_command_text, " RELEASE_PROCESSOR "); 
		return _concur_command_text;
	case constant_create_sep_obj:
		strcpy(_concur_command_text, " CREATE_SEP_OBJ "); 
		return _concur_command_text;
	case constant_creation_feature_parameter:
		strcpy(_concur_command_text, " CREATION_FEATURE_PARAMETER "); 
		return _concur_command_text;
	case constant_end_of_request:
		strcpy(_concur_command_text, " END_OF_REQUEST "); 
		return _concur_command_text;
	case constant_sep_child:
		strcpy(_concur_command_text, " CONNECTION_FROM_SEP_CHILD "); 
		return _concur_command_text;
	case constant_sep_child_info:
		strcpy(_concur_command_text, " INFORMATION_FROM_SEP_CHILD "); 
		return _concur_command_text;
	case constant_message_ack:
		strcpy(_concur_command_text, " MESSAGE_ACK "); 
		return _concur_command_text;
	case constant_execute_procedure:
		strcpy(_concur_command_text, " EXECUTE_PROCEDURE "); 
		return _concur_command_text;
	case constant_execute_query:
		strcpy(_concur_command_text, " EXECUTE_QUERY "); 
		return _concur_command_text;
	case constant_query_result_ack:
		strcpy(_concur_command_text, " QUERY_RESULT_ACK "); 
		return _concur_command_text;
	case constant_report_error:
		strcpy(_concur_command_text, " REPORT_ERROR "); 
		return _concur_command_text;
	case constant_stop_execution:
		strcpy(_concur_command_text, " STOP_EXECUTION "); 
		return _concur_command_text;
	case constant_start_sep_obj_ok:
		strcpy(_concur_command_text, " START_SEP_OBJ_OK "); 
		return _concur_command_text;
	case constant_exit_ok:
		strcpy(_concur_command_text, " EXIT_OK "); 
		return _concur_command_text;
	case constant_not_defined:
		strcpy(_concur_command_text, " NOT_DEFINED "); 
		return _concur_command_text;
	default :
		sprintf(_concur_command_text, " UNKNOWN COMMAND CODE(%d) ", cmd); 
		return _concur_command_text;
	}
}


char valid_command(cmd)
EIF_INTEGER cmd;
{
/* is the request a valid request? If the code is a pre-defined 
 * request code, return 1; else return 0.
*/

	switch (cmd) {
	case constant_reserve:
	case constant_reserve_ack:
	case constant_reserve_fail:
	case constant_register_first_from_parent:
	case constant_register:
	case constant_register_ack:
	case constant_register_ack_with_root_oid:
	case constant_unregister:
	case constant_release:
	case constant_query_result:
	case constant_ack_for_procedure:
	case constant_middle_result_of_importation:
	case constant_release_sep_obj:
	case constant_release_processor:
	case constant_create_sep_obj:
	case constant_creation_feature_parameter:
	case constant_end_of_request:
	case constant_sep_child:
	case constant_sep_child_info:
	case constant_message_ack:
	case constant_execute_procedure:
	case constant_execute_query:
	case constant_query_result_ack:
	case constant_report_error:
	case constant_stop_execution:
	case constant_start_sep_obj_ok:
	case constant_exit_ok:
		return 1;
	default :
		return 0;
	}
}


/*-----------------------------------------------------------------------*/
/*                                                                       */
/*                         Primitives for REQUEST                        */
/*                                                                       */
/*-----------------------------------------------------------------------*/

void directly_get_command(s)
EIF_INTEGER s;
{
/* read a request's head(include request's code, parameter number and
 * object ID, class name, feature name, acknowlegnement information for
 * application request) from network.
 * When we can't get available data from the network, it's hard to 
 * determine if the network is ok or not(i.e, connection is resetted,
 * network is down etc).
*/
	EIF_INTEGER para_item_length;
	EIF_INTEGER rc;

	char *get_buf;


	c_concur_set_blocking(s);
/*
	_concur_command = c_concur_read_int(s);
	_concur_para_num = c_concur_read_int(s);
*/
	get_buf = c_concur_read_stream(s, constant_sizeofint+constant_sizeofint);
	_concur_command = ntohl(*((EIF_INTEGER *)get_buf));
	_concur_para_num = ntohl(*((EIF_INTEGER *)(get_buf+constant_sizeofint)));
#ifdef DISP_MSG
	printf(GET_CMD_MSG1, _concur_pid, s, command_text(_concur_command));	
#endif
	if (!valid_command(_concur_command)) {
		sprintf(crash_info, CURAPPERR3, error_info(), command_text(_concur_command));
		c_raise_concur_exception(exception_unexpected_request);
	}
	if (_concur_command >= 0) {
		/* Now, get OID */
		_concur_command_oid = c_concur_read_int(s);
		/* Now, get class name */ 
		para_item_length = c_concur_read_int(s);
		if (para_item_length > constant_max_class_name_len) {
			add_nl;
			sprintf(crash_info, CURERR1, para_item_length-constant_max_class_name_len);
			c_raise_concur_exception(exception_network_connection_crash);
		}
		strcpy(_concur_command_class, c_concur_read_stream(s, para_item_length));
		/* Now, get feature name */ 
		para_item_length = c_concur_read_int(s);
		if (para_item_length > constant_max_feature_name_len) {
			add_nl;
			sprintf(crash_info, CURERR2, para_item_length-constant_max_class_name_len);
			c_raise_concur_exception(exception_network_connection_crash);
		}
		strcpy(_concur_command_feature, c_concur_read_stream(s, para_item_length));
		/* Now, get acknowledge option */
		_concur_command_ack = c_concur_read_int(s);
#ifdef DISP_MSG
		printf(GET_CMD_MSG2, _concur_command_oid, _concur_command_class, _concur_command_feature, _concur_command_ack);
#endif
	}
#ifdef DISP_MSG
	printf(GET_CMD_MSG3, _concur_para_num);
#endif

	if (_concur_command == constant_report_error) {
		get_data(s);
		add_nl;
		sprintf(crash_info, CURAPPERR11);
		c_raise_concur_exception(exception_unexpected_request);
	}

	return;
}

void get_command(s)
EIF_INTEGER s;
{
/* read a request's head(include request's code, parameter number and
 * object ID, class name, feature name, acknowlegnement information for
 * application request) from network.
 * When we can't get available data from the network, it's hard to 
 * determine if the network is ok or not(i.e, connection is resetted,
 * network is down etc).
*/
	EIF_INTEGER para_item_length;
	EIF_INTEGER rc;

	EIF_INTEGER ready_nb, tmp_count;
	fd_set tmp_read_mask;
	fd_set tmp_except_mask;
	
	set_mask(s);
	if (_concur_is_creating_sep_child) {
		unset_mask(_concur_sock);
	}
	for(;;) {
		ready_nb = 0;
		while (ready_nb == 0) {
			memcpy(&tmp_read_mask, &_concur_mask, sizeof(fd_set));
			memcpy(&tmp_except_mask, &_concur_mask, sizeof(fd_set));
			c_concur_select(ready_nb, _concur_mask_limit.up+1, &tmp_read_mask, NULL, &tmp_except_mask, -1, 0);
#ifndef STOP_GC
#ifdef GC_ON_CPU_TIME
			if (c_wait_time() >= constant_cpu_period) {
#else
			if (c_wait_time() >= constant_absolute_period) {
#endif
				plsc();
				c_reset_timer();
			}
#endif
		}

		if (FD_ISSET(_concur_sock, &tmp_read_mask)) {
		/* there is 'connection" request, process it */
			ready_nb--;
			/* we will process the request on one socket, so
			 * decrease the number.
			*/
			process_connection();
		}
	
		if (ready_nb) {
			tmp_count = process_exception(&tmp_except_mask);
			ready_nb -= tmp_count;
		}
		if (ready_nb) {
			tmp_count = has_msg_from_pc(&tmp_read_mask);
			if (tmp_count) {
			/* There is message from the current processor's child or parent */
			/* the following statements are used to process crash.
			 * They will causes the execution of the processor terminate.
			 * so whenever the execution comes here, the following statements
			 * beyond the "if" statement will not be executed any more.
			*/
				process_request_from_parent();
				process_request_from_child(1);
			}
			ready_nb -= tmp_count;
		}
			
		if (ready_nb) 
			if (FD_ISSET(s, &tmp_read_mask)) {
				directly_get_command(s);
				unset_mask(s);
				if (_concur_is_creating_sep_child && !(FD_ISSET(_concur_sock, &_concur_mask))) {
					set_mask(_concur_sock);
				}
				return;
			}
			else {
				idle_usage(ready_nb, &tmp_read_mask, 0);
			}	
	}
}

void get_data(s)
EIF_INTEGER s;
{
/* read a request's parameters into parameter array from network. */
/* For Separate_reference data, we will protect the SEP_OBJ object by
 * "henter", so once the SEP_OBJ object is accessed, the obejct should be
 * weaned by the program which uses the parameter.
*/
	EIF_BOOLEAN has_sep_obj=0;
	EIF_INTEGER idx;
	EIF_INTEGER para_item_length;
	char tmp_hname[constant_max_host_name_len+1];
	EIF_INTEGER tmp_pid, tmp_oid, tmp_type;

	char *get_buf;
	char send_buf[2*constant_sizeofint];

	c_concur_set_blocking(s);
	adjust_parameter_array(_concur_para_num);
	for(idx=0, has_sep_obj=0; idx < _concur_para_num; idx++) {
/*
		_concur_paras[idx].type = c_concur_read_int(s);
		para_item_length = c_concur_read_int(s);
*/
		get_buf = c_concur_read_stream(s, constant_sizeofint+constant_sizeofint);
		_concur_paras[idx].type = ntohl(*((EIF_INTEGER *)get_buf));
		para_item_length = ntohl(*((EIF_INTEGER *)(get_buf+constant_sizeofint)));
#ifdef DISP_MSG
		printf(GET_DATA_MSG1, _concur_pid, s, _concur_paras[idx].type, para_item_length);
#endif
		switch (_concur_paras[idx].type) {
			case Integer_type:
				_concur_paras[idx].uval.int_val = c_concur_read_int(s);
#ifdef DISP_MSG
				printf("  VAL: %d", _concur_paras[idx].uval.int_val);
#endif
				break;
			case Real_type:
				_concur_paras[idx].uval.real_val = c_concur_read_real(s);
#ifdef DISP_MSG
				printf("  VAL: %f", _concur_paras[idx].uval.real_val);
#endif
				break;
			case Double_type:
				_concur_paras[idx].uval.double_val = c_concur_read_double(s);
#ifdef DISP_MSG
				printf("  VAL: %f", _concur_paras[idx].uval.double_val);
#endif
				break;
			case Boolean_type:
				_concur_paras[idx].uval.bool_val = c_concur_read_int(s);
#ifdef DISP_MSG
				printf("  VAL: %d", _concur_paras[idx].uval.bool_val);
#endif
				break;
			case Character_type:
			case String_type:
				if (para_item_length < 0) {
				/* It's a NULL string */
					if (_concur_paras[idx].str_len) 
						_concur_paras[idx].str_len = - abs(_concur_paras[idx].str_len);
					else {
						_concur_paras[idx].str_len = - constant_min_str_len;
						_concur_paras[idx].str_val = (char *)malloc(constant_min_str_len);
						valid_memory(_concur_paras[idx].str_val);
					}
					_concur_paras[idx].str_val[0] = '\0';
#ifdef DISP_MSG
					printf("  VAL: NULL");
#endif
				}
				else {
					if (para_item_length)
					/* It's a  non-EMPTY string */
						set_str_val_into_parameter(_concur_paras + idx, c_concur_read_stream(s, para_item_length));
					else
					/* It's a  EMPTY string */
						set_str_val_into_parameter(_concur_paras + idx, "");
#ifdef DISP_MSG
					printf("  VAL: %s", _concur_paras[idx].str_val);
#endif
				}
				break;
			case Separate_reference:
				/* Read hostname */
				strcpy(tmp_hname, c_concur_read_stream(s, para_item_length));
				/* Read pid */
				tmp_pid = c_concur_read_int(s);
				tmp_pid = c_concur_read_int(s);
				/* Read data type */
/*				tmp_type = c_concur_read_int(s); */
				/* Read OID */
				tmp_oid = c_concur_read_int(s);
				tmp_oid = c_concur_read_int(s);
				_concur_paras[idx].uval.s_obj = henter(create_sep_obj(tmp_hname,tmp_pid, tmp_oid));
				/* protect the object in hector */	
				if (eif_access(_concur_paras[idx].uval.s_obj) != NULL)
					has_sep_obj = 1;
				break;
			default:
				sprintf(_concur_crash_info, CURERR3, _concur_paras[idx].type);
				c_raise_concur_exception(exception_network_connection_crash);
		}
#ifdef DISP_MSG
		printf("\n");
#endif
	}	
	if (_concur_command > 0 && has_sep_obj) {
    /* The current processor gets some separate object proxies, so it
	 * sends back acknowledge message(MESSAGE_ACK) to the sender.
	*/
		*(EIF_INTEGER *)send_buf = htonl(constant_message_ack);
		*(EIF_INTEGER *)(send_buf+constant_sizeofint) = htonl(0);
		c_concur_put_stream(s, send_buf, 2*constant_sizeofint);
#ifdef DISP_MSG
		printf("%d/%d  Send Command MESSAGE_ACK   PARA#: 0\n", _concur_pid, s);
#endif
	}

	return;
}

void send_register_ack_with_root_oid(s)
EIF_INTEGER s;
{
/* a remote client REGISTERed the root object of the processor, but 
 * it does not know the OID of the root object, so in the same time
 * of acknowledging the remote client's REGISTER request, send it
 * the OID of the root object of the processor.
*/
	EIF_INTEGER root_oid;
	
	char send_buf[5*constant_sizeofint];

	gc_stop();
	root_oid = get_oid_from_address(root_obj);
	*(EIF_INTEGER *)send_buf = htonl(constant_register_ack_with_root_oid);
	*(EIF_INTEGER *)(send_buf+constant_sizeofint) = htonl(1);
	*(EIF_INTEGER *)(send_buf+2*constant_sizeofint) = htonl(Integer_type);
	*(EIF_INTEGER *)(send_buf+3*constant_sizeofint) = htonl(constant_sizeofint);
	*(EIF_INTEGER *)(send_buf+4*constant_sizeofint) = htonl(root_oid);
	c_concur_put_stream(s, send_buf, 5*constant_sizeofint);
	change_ref_table_and_exported_obj_list(_concur_paras[0].str_val, _concur_paras[1].uval.int_val, root_oid, 1);
#ifdef tSTOP_GC
	gc_run();
#endif
#ifdef DISP_MSG
	printf("%d/%d Sent Command REGISTER_ACK_WITH_ROOT_OID. PARA#=1; VAL=%d. \n", _concur_pid, s, root_oid);
#endif
	return;
}

void send_register_ack(s)
EIF_INTEGER s;
{
/* Acknowledgement for REGISTER request. */
	char send_buf[2*constant_sizeofint];

	gc_stop();
#ifdef DISP_MSG
	printf("%d/%d Sent Command REGISTER_ACK \n", _concur_pid, s);
#endif
	*(EIF_INTEGER *)send_buf = htonl(constant_register_ack);
	*(EIF_INTEGER *)(send_buf+constant_sizeofint) = htonl(0);
	c_concur_put_stream(s, send_buf, 2*constant_sizeofint);
#ifdef tSTOP_GC
	gc_run();
#endif   
	return;
}



/* the following two Macro are only used by "send_command". So
 * we define them here. In fact, most of the parameters of the
 * macros are not necessary, we keep them there just for future changes.
*/

#define fill_buf(s, buf, blen, data, dlen) \
	if (blen+dlen<=constant_command_buffer_len) {\
		memcpy(buf+blen, data, dlen); \
		blen += dlen; \
	} else { \
		if (blen) \
			c_concur_put_stream(s, buf, blen); \
		blen = 0; \
		if (dlen>=constant_command_buffer_len)  \
			c_concur_put_stream(s, data, dlen); \
		else { \
			memcpy(buf+blen, data, dlen); \
			blen += dlen; \
		} \
	}

/* the following Macro uses an EIF_INTEGER variable "tmp_len", 
 * which is defined in "send_command".
*/

#define fill_buf_with_int(s, buf, blen, int_val) \
		tmp_len = htonl(int_val); \
		fill_buf(s, buf, blen, &tmp_len, constant_sizeofint)	

void send_command(s)
EIF_INTEGER s;
{
/* write a request's all information, including parameters onto network. */
/* for Separate_reference parameter, we assume that the SEP_OBJ object 
 * has been protected by "henter" when it's filled into parameter array, so in
 * the procedure,  the SEP_OBJ object will be weaned when it's sent.
*/
	EIF_INTEGER tmp;
	EIF_BOOLEAN has_sep_obj=0;
	EIF_POINTER tmp_str;
	char void_str[] = "Void Ref";
	
	char send_buf[constant_command_buffer_len];
	EIF_INTEGER send_data_len=0;
	EIF_INTEGER tmp_len;

	gc_stop();
#ifdef DISP_MSG
	printf("\n%d/%d Send Command %s ", _concur_pid, s, command_text(_concur_command));
#endif
	/* to send request code "_concur_command" */
	fill_buf_with_int(s, send_buf, send_data_len, _concur_command);
	/* to send request's parameter number "_concur_para_num" */
	fill_buf_with_int(s, send_buf, send_data_len, _concur_para_num);

	if (_concur_command >= 0) {
#ifdef DISP_MSG
		printf(" OID:%d, CLASS:%s, FEATURE:%s, ACK:%d ", _concur_command_oid, _concur_command_class, _concur_command_feature, _concur_command_ack);
#endif
		/* to send the callee's OID "_concur_command_oid" */
		fill_buf_with_int(s, send_buf, send_data_len, _concur_command_oid);
		/* to send the callee's class name */
		fill_buf_with_int(s, send_buf, send_data_len, strlen(_concur_command_class));
		fill_buf(s, send_buf, send_data_len, _concur_command_class, (int)strlen(_concur_command_class));
		/* to send the callee's feature name */
		fill_buf_with_int(s, send_buf, send_data_len, strlen(_concur_command_feature));
		fill_buf(s, send_buf, send_data_len, _concur_command_feature, (int)strlen(_concur_command_feature));
		/* to send the acknowledgement indicator "_concur_command_ack" */
		fill_buf_with_int(s, send_buf, send_data_len, _concur_command_ack);
	}
#ifdef DISP_MSG
	printf(" PARA#:%d\n", _concur_para_num);
#endif

	/* to send the request's parameters */
	for(has_sep_obj=0, tmp=0; tmp<_concur_para_num; tmp++) {
		if ((send_data_len + constant_sizeofint + constant_sizeofdouble) > constant_command_buffer_len) {
		/* we expect that a parameter's type and length arrive at the destination at
		 * the same time. So, we should guarantee that they are always in the same
		 * message.
		*/
			c_concur_put_stream(s, send_buf, send_data_len);
			send_data_len = 0;
		}
		/* to send the parameter's data type*/
		fill_buf_with_int(s, send_buf, send_data_len, _concur_paras[tmp].type);
#ifdef DISP_MSG
		printf("%d/%d Para type: %d, ", _concur_pid, s, _concur_paras[tmp].type);
#endif
		switch (_concur_paras[tmp].type) {
			case Integer_type:
				/* to send the EIF_INTEGER parameter's data length */
				fill_buf_with_int(s, send_buf, send_data_len, constant_sizeofint);
				/* to send the EIF_INTEGER parameter's value */
				fill_buf_with_int(s, send_buf, send_data_len, _concur_paras[tmp].uval.int_val);
#ifdef DISP_MSG
		printf(" len: %d, VAL: %d\n", constant_sizeofint, _concur_paras[tmp].uval.int_val);
#endif
				break;
			case Real_type:
				/* to send the EIF_REAL parameter's data length */
				fill_buf_with_int(s, send_buf, send_data_len, constant_sizeofreal);
				/* to send the EIF_REAL parameter's value */
				fill_buf(s, send_buf, send_data_len, &(_concur_paras[tmp].uval.real_val), constant_sizeofreal);
#ifdef DISP_MSG
		printf(" len: %d, VAL: %f\n", constant_sizeofreal, _concur_paras[tmp].uval.real_val);
#endif
				break;
			case Double_type:
				/* to send the EIF_DOUBLE parameter's data length */
				fill_buf_with_int(s, send_buf, send_data_len, constant_sizeofdouble);
				/* to send the EIF_DOUBLE parameter's value */
				fill_buf(s, send_buf, send_data_len, &(_concur_paras[tmp].uval.double_val), constant_sizeofdouble);
#ifdef DISP_MSG
		printf(" len: %d, VAL: %f\n", constant_sizeofdouble, _concur_paras[tmp].uval.double_val);
#endif
				break;
			case Boolean_type:
				/* to send the EIF_BOOLEAN parameter's data length */
				fill_buf_with_int(s, send_buf, send_data_len, constant_sizeofint);
				/* to send the EIF_BOOLEAN parameter's value */
				fill_buf_with_int(s, send_buf, send_data_len, _concur_paras[tmp].uval.bool_val);
#ifdef DISP_MSG
		printf(" len: %d, VAL: %d\n", constant_sizeofint, _concur_paras[tmp].uval.bool_val);
#endif
				break;
			case String_type:
			case Character_type:
				if (_concur_paras[tmp].str_len < 0)  {
				/* It's a NULL string */
 					/* to send the STRING's length. -1 indicates that
  					 * it's a NULL string.
					*/
					fill_buf_with_int(s, send_buf, send_data_len, -1);
				}
				else {
					/* to send the STRING parameter's data length */
					fill_buf_with_int(s, send_buf, send_data_len, strlen(_concur_paras[tmp].str_val));
					/* to send the STRING parameter's data value */
					if (strlen(_concur_paras[tmp].str_val)) {
					/* For EMPTY string, just its length(0) is sent */
						fill_buf(s, send_buf, send_data_len, _concur_paras[tmp].str_val, (int)strlen(_concur_paras[tmp].str_val));
					}
#ifdef DISP_MSG
		printf(" len: %d, VAL: %s\n", strlen(_concur_paras[tmp].str_val), _concur_paras[tmp].str_val);
#endif
				}
				break;
			case Separate_reference:
				if (eif_access(_concur_paras[tmp].uval.s_obj) != NULL) {
					has_sep_obj = 1;
					tmp_str = get_c_format_of_eif_string((EIF_POINTER)eif_access(_concur_paras[tmp].uval.s_obj), "hostname");
					/* to send the separate object's HOST NAME: length and value */
					fill_buf_with_int(s, send_buf, send_data_len, strlen(tmp_str));
					fill_buf(s, send_buf, send_data_len, tmp_str, (int)strlen(tmp_str));
					/* to send the separate object's PID: length and value */
					fill_buf_with_int(s, send_buf, send_data_len, constant_sizeofint);
					tmp_len = eif_field(eif_access(_concur_paras[tmp].uval.s_obj), "pid", EIF_INTEGER);
					fill_buf_with_int(s, send_buf, send_data_len, tmp_len);
					/* to send the separate object's OID: length and value */
					fill_buf_with_int(s, send_buf, send_data_len, constant_sizeofint);
					tmp_len = eif_field(eif_access(_concur_paras[tmp].uval.s_obj), "oid", EIF_INTEGER);
					fill_buf_with_int(s, send_buf, send_data_len, tmp_len);

					tmp_str = eif_wean(_concur_paras[tmp].uval.s_obj);
					/* free the object from hector so that it can be collected */
				}
				else {
				/* we use <Void_str, -1, -1> stands for a NULL separate object */
					/* to send the separate object's HOST NAME: length and value */
					fill_buf_with_int(s, send_buf, send_data_len, strlen(void_str));
					fill_buf(s, send_buf, send_data_len, void_str, (int)strlen(void_str));
					/* to send the separate object's PID: length and value */
					fill_buf_with_int(s, send_buf, send_data_len, constant_sizeofint);
					fill_buf_with_int(s, send_buf, send_data_len, -1);
					/* to send the separate object's OID: length and value */
					fill_buf_with_int(s, send_buf, send_data_len, constant_sizeofint);
					fill_buf_with_int(s, send_buf, send_data_len, -1);
				}	
#ifdef DISP_MSG
		printf(" Separate Reference\n");
#endif
				break;
			default:
				add_nl;
				sprintf(crash_info, CURERR4, _concur_paras[tmp].type);
				c_raise_concur_exception(exception_implementation_error);
				return;
		}
	}

	if (send_data_len)
		c_concur_put_stream(s, send_buf, send_data_len);

	if (_concur_command >= 0 && has_sep_obj ) {
	/* Some separate object proxies are sent out. For each separate object
	 * proxy, the receiver may send a REGISTER to the corresponding processor
	 * (if the proxy is not NULL and the corresponding object has not been 
	 * imported by the receiver). After the receiver gets all data, it will 
	 * send a MESSAGE_ACK back to the current processor(sender). So, we should 
	 * wait here until get a MESSAGE_ACK request from the receiver. 
	 * It's possible that the sender gets REGISTER request(s) from the receiver.
	 * But other requests from the receiver are impossible.
	*/ 
		_concur_command = constant_not_defined;
		while (_concur_command != constant_message_ack) {
			get_cmd_data(s);
			if (_concur_command == constant_register) {
				send_register_ack(s);
				change_ref_table_and_exported_obj_list(_concur_paras[0].str_val, _concur_paras[1].uval.int_val, _concur_paras[2].uval.int_val, 1);
			}
			else if (_concur_command != constant_message_ack) {
				add_nl;
				sprintf(crash_info, CURIMPERR2, "MESSAGE_ACK/REGISTER", command_text(_concur_command), "send_command");
				c_raise_concur_exception(exception_unexpected_request);
			}
		}
	}
#ifdef tSTOP_GC
	gc_run();
#endif
	return;
}

/*-----------------------------------------------------------------------*/
/*                                                                       */
/*                     Utilities for LOCAL SERVER                        */
/*                                                                       */
/*-----------------------------------------------------------------------*/

void server_execute(case_process)
EIF_PROC case_process;
{
/* perform server function for the local processor.
 * Whenever it get a request from a client, it servers it.
 * It supports FCFS principle, keeps the atomicity of an application 
 * operation.
 * Simply to say(not exactly), it finishes when there is no pending client
 * (i.e., no reference to the local objects from other 
 * processors).
*/

	EIF_BOOLEAN stop; /* whenever it's true, we can exit from the loop */

	CHILD *tmp_child;
	CLIENT *tmp_client;
	fd_set tmp_read_mask;
	fd_set tmp_except_mask;
	int ready_nb, tmp_count;


    c_reset_timer();
	/* used to decide when to start GC. 
	 * In the implementation, we use GC to release network connection
	 * between separate objects, we will start GC explicitly once after
	 * a certain period. The function call here is to start the "TIMER".
	*/


#ifndef STOP_GC
			plsc();
#endif


	if (_concur_terminatable && _concur_cli_list_count == 0)
		stop = 1;
	else
		stop = 0;

	for(_concur_current_client=NULL; !stop; ) {

		ready_nb = 0;
		while (ready_nb == 0) {
			memcpy(&tmp_read_mask, &_concur_mask, sizeof(fd_set));
			memcpy(&tmp_except_mask, &_concur_mask, sizeof(fd_set));
			c_concur_select(ready_nb, _concur_mask_limit.up+1, &tmp_read_mask, NULL, &tmp_except_mask, constant_period/1000, constant_period%1000);
#ifndef STOP_GC
#ifdef GC_ON_CPU_TIME
			if (c_wait_time() >= constant_cpu_period) {
#else
			if (c_wait_time() >= constant_absolute_period) {
#endif
				plsc();
				c_reset_timer();
			}
#endif
		}

		if (FD_ISSET(_concur_sock, &tmp_read_mask)) {
		/* there is 'connection" request, process it */
			ready_nb--;
			/* we will process the request on one socket, so
			 * decrease the number.
			*/
			process_connection();
		}

		if (ready_nb) {
			tmp_count = process_exception(&tmp_except_mask);
			ready_nb -= tmp_count;
		}
		if (ready_nb) {
			tmp_count = has_msg_from_pc(&tmp_read_mask);
			if (tmp_count) {
			/* There is message from the current processor's child or parent */
			/* the following statements are used to process crash.
			 * They will causes the execution of the processor terminate.
			 * so whenever the execution comes here, the following statements
			 * beyond the "if" statement will not be executed any more.
			*/
				process_request_from_parent();
				process_request_from_child(1);
			}
			ready_nb -= tmp_count;
		}
                                                      
		if (ready_nb) {
			if (_concur_current_client) {
				if (FD_ISSET(_concur_current_client->sock, &tmp_read_mask)) {
				/* There is request from the current client, so processes it
				 * and then try to get the next request from the client
				 * until we finished the atomic application operation
				 * or there is no request arrived at the moment,
				 * in the case, we process some of other clients'
				 * requests.
				*/
					directly_get_cmd_data(_concur_current_client->sock);
#ifdef WORKBENCH
					if (_concur_command>=0 && !_concur_invariant_checked) {
					/* the condition means that the current request is a 
					 * application request for the initialization of the 
					 * separate object. So after the initialization, 
					 * we should check the object's 
					 * invariants.
					*/
						(case_process)();
						RTCI(root_obj);
					}
					else
						(case_process)();
#else
					(case_process)();
#endif
					/* If this is the last request of the application
					 * operation, we should try to get another client as
					 * the current and server it.
					*/
					ready_nb--;
					if (!_concur_current_client)
						if (_concur_blk_cli_list_count) {
							if (ready_nb)
								idle_usage(ready_nb, &tmp_read_mask, 0);
							_concur_current_client = take_head_from_blocked_client_list();
							/* The blocked request must be RESERVE_SEP_OBJ. If 
							 * REJECT to the request is available, then no request
							 * will be blocked here.
							*/
							_concur_command = (_concur_current_client->req_buf).command;
							_concur_para_num = (_concur_current_client->req_buf).para_num;
							(_concur_current_client->req_buf).command = constant_not_defined;
							get_data(_concur_current_client->sock);
							if (_concur_command != constant_reserve) {
		       			     	add_nl;
					            sprintf(crash_info, CURIMPERR2, "RESERVE_SEP_OBJ", command_text(_concur_command), "server_exec1");
						        c_raise_concur_exception(exception_unexpected_request);
							}
							(case_process)();					
						}
						else
							if (ready_nb)
								idle_usage(ready_nb, &tmp_read_mask, 1);
					else
						if (ready_nb)
							idle_usage(ready_nb, &tmp_read_mask, 0);
				}
				else {
				/* There are requests from other clients, processes them */
					idle_usage(ready_nb, &tmp_read_mask, 0);
				}
			}	
			else {
			/* Process the requests from the clients, then Choose the first 
			 * client who has application request as 
			 * the current client and process its requests.
			*/
				if (_concur_blk_cli_list_count) 
					idle_usage(ready_nb, &tmp_read_mask, 0);
				else
					idle_usage(ready_nb, &tmp_read_mask, 1);
				if (!_concur_current_client && _concur_blk_cli_list_count) {
					_concur_current_client = take_head_from_blocked_client_list();
					/* The blocked request must be RESERVE_SEP_OBJ. If 
					 * REJECT to the request is available, then no request
					 * will be blocked here.
					*/
					_concur_command = (_concur_current_client->req_buf).command;
					_concur_para_num = (_concur_current_client->req_buf).para_num;
					(_concur_current_client->req_buf).command = constant_not_defined;
					get_data(_concur_current_client->sock);
					if (_concur_command != constant_reserve) {
			            add_nl;
					    sprintf(crash_info, CURIMPERR2, "RESERVE_SEP_OBJ", command_text(_concur_command), "server_exec2");
				        c_raise_concur_exception(exception_unexpected_request);
			        }
					(case_process)();					
				}
			}
		}
		if (_concur_terminatable && _concur_cli_list_count == 0 && !_concur_current_client)
			stop = 1;
	}
	
	/* No client to serve again, so we call GC to disconnect all
	 * network connection, and release all resources(references
     * to the objects on ther processors.
	*/

/*
printf("\n\n\n%d(%s) We have no client to server again, so to release %d servers\n", _concur_pid, _concur_class_name_of_root_obj, _concur_ser_list_count);
*/

#ifndef STOP_GC
	plsc();/* It's necessary here, just release server list is not enough.*/
#endif

	release_server_list();
	release_imported_objects();
	
	/* the following statements are used to process crash. 
	 * so that we can exit gracefully when crash happens.
	*/
	for(; _concur_child_list_count>0; ) {
		memcpy(&tmp_read_mask, &_concur_mask, sizeof(fd_set));
		memcpy(&tmp_except_mask, &_concur_mask, sizeof(fd_set));
		c_concur_select(ready_nb, _concur_mask_limit.up+1, &tmp_read_mask, NULL, &tmp_except_mask, -1, 0);
		process_request_from_parent();
		process_request_from_child(1);
	}
	if (_concur_parent != NULL) {
		_concur_command = constant_exit_ok;
		_concur_para_num = 0;
		send_command(_concur_parent->sock);
		c_concur_close_socket(_concur_parent->sock);
		_concur_parent->sock = -1;
	}

	/* Close current processor's server socket. */
	c_concur_close_socket(_concur_sock);
	/* free the memory resource used by the parameter array. */
	free_parameter_array(_concur_paras, _concur_paras_size);
	
	return;
}


/*-----------------------------------------------------------------------*/
/*                                                                       */
/*                  Utilities For Remote Server                          */
/*                                                                       */
/*-----------------------------------------------------------------------*/

EIF_OBJ remote_server(hostn, port)
char *hostn;
EIF_INTEGER port;
{
/* create a proxy for a remote server, return DIRECT address. 
 * the process is very similar with "create_sep_obj".
*/

    EIF_REFERENCE ret;
    char * host_obj;
    EIF_INTEGER sep_obj_id;
    EIF_PROC c_make_without_connection, c_make, c_set_host_port, c_set_sock, c_set_proxy_id, c_set_oid;


    EIF_INTEGER command_bak;
    EIF_INTEGER para_num_bak;
    PARAMETER *paras_bak;
    EIF_INTEGER paras_size_bak;
    EIF_REFERENCE my_str;

    EIF_INTEGER proxy_id;

	EIF_INTEGER real_root_oid;
    EIF_INTEGER sock;

    if (port < 0)
        return NULL;
    else {
        proxy_id = get_proxy_oid_of_inported_object(hostn, port, constant_root_oid);
        if (proxy_id) {
#ifdef DISP_LIST
printf("The REMOTE SERVER(%s, %d)'s root object has been imported before.!\n", hostn, port);
print_ref_table_and_exported_object();
#endif
            return eif_id_object(proxy_id);
            /* return unprotected address of the proxy */
        }

        sep_obj_id = eif_type_id("SEP_OBJ");
        ret = eif_create(sep_obj_id); /* create a proxy */
        proxy_id = eif_general_object_id(ret);/* get OID for the proxy */

        c_make_without_connection = eif_proc("make_without_connection", sep_obj_id);
        c_make = eif_proc("make", sep_obj_id);
        c_set_host_port = eif_proc("set_host_port", sep_obj_id);
        c_set_sock = eif_proc("set_sock", sep_obj_id);
        c_set_proxy_id = eif_proc("set_proxy_id", sep_obj_id);
        c_set_oid = eif_proc("set_oid", sep_obj_id);

        (c_set_proxy_id)(eif_access(ret), proxy_id);
        host_obj = makestr(hostn, strlen(hostn));
        my_str = henter(host_obj);  /* protect the string in hector */

		/* set up the network connection to the remote server */
        if (exist_in_server_list(hostn, port)) {
		/* if there is a connection to the remote server, use it */
            (c_make_without_connection)(eif_access(ret), constant_root_oid);
            (c_set_host_port)(eif_access(ret), eif_access(my_str), port);
            sock = get_sock_from_server_list(hostn, port);
            (c_set_sock)(eif_access(ret), sock);
        }
        else {
            (c_make)(eif_access(ret), eif_access(my_str), port, constant_root_oid);
            sock = eif_field(eif_access(ret), "sock", EIF_INTEGER);
            add_to_server_list(hostn, port, sock);
        }

		/* now, get the real OID for the root object */
		command_bak = _concur_command;
        para_num_bak = _concur_para_num;
        paras_bak = _concur_paras;
        paras_size_bak = _concur_paras_size;

        _concur_paras = NULL;
        _concur_paras_size = 0L;
        adjust_parameter_array(3);

        _concur_paras[0].type = String_type;
        set_str_val_into_parameter(_concur_paras, _concur_hostname);

        _concur_paras[1].type = Integer_type;
        _concur_paras[1].uval.int_val = _concur_pid;

        _concur_paras[2].type = Integer_type;
        _concur_paras[2].uval.int_val = constant_root_oid;

        _concur_command = constant_register;
        _concur_para_num = 3;

  		send_command(sock);

        get_cmd_data(sock);
        if (_concur_command != constant_register_ack_with_root_oid) {
			add_nl;
			sprintf(crash_info, CURIMPERR3, command_text(_concur_command));
            c_raise_concur_exception(exception_unexpected_request);
        }

		/* the following statements are to set the real OID of the 
		 * remote server's root to the proxy
		*/
		real_root_oid = _concur_paras[0].uval.int_val;
		/* we use negative value for the root OID of remote server so 
		 * that function get_proxy_oid_of_inported_object() can
		 * distinguish it.
		*/ 
        (c_set_oid)(eif_access(ret), -real_root_oid);
		insert_into_imported_object_table(hostn, port, -real_root_oid, proxy_id);		

        free_parameter_array(_concur_paras, _concur_paras_size);
        _concur_command = command_bak;
        _concur_paras = paras_bak;
        _concur_paras_size = paras_size_bak;
        _concur_para_num = para_num_bak;

        host_obj = eif_wean(my_str); /* free the string from hector */
        return eif_wean(ret);
        /* return direct address and free the object from hector */
    }
}

EIF_OBJ remote_server_by_index(idx)
EIF_INTEGER idx;
{
/* create a SEP_OBJ proxy for a remote server, and return DIRECT address. */
	EIF_TYPE_ID sep_obj_id;
	char *tmp_str;
	EIF_REFERENCE my_str;
	EIF_REFERENCE my_sep_obj;
	EIF_PROC c_make;

	if (idx >= _concur_rem_ser_count) {
		add_nl;
		sprintf(crash_info, CURAPPERR5, idx, _concur_rem_ser_count);
		c_raise_concur_exception(exception_invalid_parameter);
	}
	
	return remote_server(_concur_rem_sers[idx].host, _concur_rem_sers[idx].port);
}

EIF_REFERENCE remote_server_by_name(name)
char *name;
{
/* create a SEP_OBJ proxy for a remote server, and return DIRECT address. */
	int idx;
	EIF_TYPE_ID sep_obj_id;
	char *tmp_str;
	EIF_REFERENCE my_str;
	EIF_REFERENCE my_sep_obj;
	EIF_PROC c_make;

	/* find the entry in REMOTE SERVER TABLE with the name. */
	for(idx=0; idx<_concur_rem_ser_count && memcmp(name, _concur_rem_sers[idx].name, strlen(name)); idx++);
	
	if (idx >= _concur_rem_ser_count) {
		add_nl;
		sprintf(crash_info, CURAPPERR6, name);
		c_raise_concur_exception(exception_invalid_parameter);
	}
	
	return remote_server(_concur_rem_sers[idx].host, _concur_rem_sers[idx].port);
}


/*-----------------------------------------------------------------------*/
/*                                                                       */
/*                   Local SERVER's responses                            */
/*                                                                       */
/*-----------------------------------------------------------------------*/

void register_a_ref(id, end_request) 
EIF_INTEGER id;
EIF_BOOLEAN end_request;
{
/* performed for REGISTER request */

	(_concur_current_client->count)++;
	send_register_ack(_concur_current_client->sock);
	change_ref_table_and_exported_obj_list(_concur_current_client->hostname, _concur_current_client->pid, id, 1);
	if (end_request) {
		add_to_client_queue(_concur_current_client);
		_concur_current_client = NULL;
	} 

	return;
}

void unregister_from_local_processor(EIF_REFERENCE hostn, EIF_INTEGER pid, EIF_INTEGER oid) {
	char host_in_c[constant_max_host_name_len+1];

	strcpy(host_in_c, (eif_strtoc)(eif_access(hostn)));
	
	change_ref_table_and_exported_obj_list(host_in_c, pid, oid, -1);
/*
printf(" Unregister_from_local_processor (host:%s, pid:%d, oid:%d)\n", host_in_c, pid,oid);
*/
	return;
}


void unregister(flag, id)
EIF_INTEGER flag;
EIF_INTEGER id;
{
	if (flag == constant_release_one) {
		change_ref_table_and_exported_obj_list(_concur_current_client->hostname, _concur_current_client->pid, id, -1);
		(_concur_current_client->count)--;
		if (_concur_current_client->count == 0) {
			if (!_concur_current_client_reserved) {
				unset_mask(_concur_current_client->sock);
				c_concur_close_socket(_concur_current_client->sock);
				_concur_current_client->sock = -2;
				free(_concur_current_client);
				_concur_current_client = NULL;
			}
			else {
				add_nl;
				strcat(_concur_crash_info, CURERR5);
				c_raise_concur_exception(exception_implementation_error);
			}
		}
		else 
			if (!_concur_current_client_reserved) {
				add_to_client_queue(_concur_current_client);
				_concur_current_client = NULL;
			}
	}
	else {
		change_ref_table_and_exported_obj_list(_concur_current_client->hostname, _concur_current_client->pid, constant_not_defined, constant_release_all);
		unset_mask(_concur_current_client->sock);
		c_concur_close_socket(_concur_current_client->sock);
		_concur_current_client->sock = -2;
		free(_concur_current_client);
		_concur_current_client = NULL;
	}

	return;
}


void tell_parent_info_of_myself(parent_host, parent_pid)
char *parent_host;
EIF_INTEGER parent_pid;
{
/* send the current processor's host name, port number and the root
 * object's OID to the parent separate object.
*/

	_concur_terminatable = 0;
	if (_concur_parent->sock < 0) {
		add_nl;
		strcat(_concur_crash_info, CURAPPERR12);
		c_raise_concur_exception(exception_implementation_error);
	}
	
	_concur_command = constant_sep_child_info;
	_concur_para_num = 3;
	adjust_parameter_array(3);

	_concur_paras[0].type = String_type;
	set_str_val_into_parameter(_concur_paras, _concur_hostname);

	_concur_paras[1].type = Integer_type;
	_concur_paras[1].uval.int_val = _concur_pid;

	_concur_paras[2].type = Integer_type;
	_concur_paras[2].uval.int_val = get_oid_from_address(root_obj);
	send_command(_concur_parent->sock);

	return;
}

void wait_sep_child_obj(direct_sep)
EIF_OBJ direct_sep;
{
/* wait the information returned by a separate child object.
 * During the waiting period, process other client's REGISTER requesters
 * (don't keep them waitting too long) if any.
*/
	CLIENT *recv=NULL, *child=NULL;
	EIF_INTEGER sep_obj_id;
	EIF_PROC c_set_oid, c_set_host_port, c_set_sock, c_set_proxy_id;
 	EIF_INTEGER tmp_sock;
	EIF_POINTER my_eif_str;
	EIF_REFERENCE sep;
	EIF_INTEGER proxy_id;

	PARAMETER * tmp_paras;
	EIF_INTEGER tmp_para_num, tmp_command;

	int rc;


	sep = henter(direct_sep);
	sep_obj_id = eif_type_id("SEP_OBJ");
	c_set_host_port = eif_proc("set_host_port", sep_obj_id);	
	c_set_sock = eif_proc("set_sock", sep_obj_id);	
	c_set_oid = eif_proc("set_oid", sep_obj_id);	
	c_set_proxy_id = eif_proc("set_proxy_id", sep_obj_id);

/*	c_concur_set_blocking(_concur_sock);*/
	for(_concur_command=constant_not_defined; _concur_command!=constant_sep_child_info; ) {
		_concur_command = constant_not_defined;
		if (child) {
		/* if the separate child has established connection, try to get
		 * SEP_CHILD_INFO first 
		*/
			rc = c_try_to_get_command(child->sock);
			switch (rc) {
				case -1:
					_concur_command = constant_not_defined;
					break;
				case -3:
	                add_nl;
                    strcat(_concur_crash_info, CURAPPERR7);
                    c_raise_concur_exception(exception_network_connection_crash);
				default:
					_concur_command = c_get_command_code();
#ifdef DISP_MSG
                printf("%d/%d Got command %s ", _concur_pid, child->sock, command_text(_concur_command));
#endif
	                if (_concur_command >= 0) {
	                    _concur_command_oid = c_get_oid();
	                    strcpy(_concur_command_class, c_get_class_name());
	                    strcpy(_concur_command_feature, c_get_feature_name());
	                   _concur_command_ack = c_get_ack();
#ifdef DISP_MSG
	                    printf(" OID:%d, CLASS:%s, FEATURE:%s, ACK:%d ", _concur_command_oid, _concur_command_class, _concur_command_feature, _concur_command_ack);
#endif
	                }
	                _concur_para_num = c_get_para_num();
#ifdef DISP_MSG
	                printf(" PARA#:%d\n", _concur_para_num);
#endif
					get_data(child->sock);
			}
		}

		if (_concur_command == constant_not_defined) {
		/* if the separate child has not established connection, or 
		 * fail to get SEP_CHILD_INFO from the child, process clients' 
		 * requests if any. 
		*/
			process_request_from_parent();
			process_request_from_child(1);
			rc = c_concur_accept(_concur_sock);
			if (rc>0) {
				recv = (CLIENT *)(malloc(sizeof(CLIENT)));
				valid_memory(recv);
				recv->type = constant_normal_client;
				recv->count = 1;
				recv->reservation = 0;
				recv->sock = rc;
				c_concur_set_blocking(recv->sock);
				get_cmd_data(recv->sock);
			}
		}


		switch (_concur_command) {
			case constant_not_defined:
				break;
			case constant_register:
			case constant_register_first_from_parent:
#ifdef DISP_LIST
		            printf("%d Before %s(on %s from <%s, %d, %d>):\n", _concur_pid,command_text(_concur_command), _concur_class_name_of_root_obj, CURGS(0), CURGI(1), CURGI(2));
		            print_ref_table_and_exported_object();
#endif
				strcpy(recv->hostname, _concur_paras[0].str_val);
				recv->pid = _concur_paras[1].uval.int_val;
				(recv->req_buf).command = constant_not_defined;
				add_to_client_queue(recv);
				if (_concur_paras[2].uval.int_val==constant_root_oid) {
				/* the register is sent from a "remote client"
				 * at first time 
				*/
					recv->type = constant_remote_client;
					send_register_ack_with_root_oid(recv->sock);
				}	
				else {
					_concur_terminatable = 1;
					if (_concur_command == constant_register)
						send_register_ack(recv->sock);
					change_ref_table_and_exported_obj_list(_concur_paras[0].str_val, _concur_paras[1].uval.int_val, _concur_paras[2].uval.int_val, 1);
				}
#ifdef DISP_LIST
		        printf("%d After %s(on %s)\n", _concur_pid, command_text(_concur_command), _concur_class_name_of_root_obj);
		        print_ref_table_and_exported_object();
#endif
				recv = NULL;
				break;
			case constant_sep_child:
				child = recv;
				recv = NULL;
#ifdef COMBINE_CREATION_WITH_INIT
				/* keep the PARAMETER ARRAY's environment */
				tmp_command = _concur_command;
				tmp_paras = _concur_paras;
				tmp_para_num = _concur_para_num;

				/* Send the creation's parameters to the separate
				 * child procesor. The parameters has been stored in
				 * the ALTERNATIVE parameter array.
				*/
				_concur_command = constant_creation_feature_parameter;
				_concur_para_num = _concur_alt_para_num;
				_concur_paras = _concur_alt_paras;
				send_command(child->sock);

				/* Restore the PARAMETER ARRAY's environment */
				_concur_command = tmp_command;
				_concur_paras = tmp_paras;
				_concur_para_num = tmp_para_num;
#endif
				break;
			case constant_sep_child_info:
				c_concur_set_blocking(child->sock);
				add_to_child_list(child);
				strcpy(child->hostname, _concur_paras[0].str_val);
				child->pid = _concur_paras[1].uval.int_val;
				
				my_eif_str = makestr(_concur_paras[0].str_val, strlen(_concur_paras[0].str_val));
				(c_set_host_port)(eif_access(sep), my_eif_str, _concur_paras[1].uval.int_val);
				(c_set_oid)(eif_access(sep), _concur_paras[2].uval.int_val);
				proxy_id = eif_general_object_id(sep);
				(c_set_proxy_id)(eif_access(sep), proxy_id);
				insert_into_imported_object_table(_concur_paras[0].str_val, _concur_paras[1].uval.int_val, _concur_paras[2].uval.int_val, proxy_id);
				break;
			default:
				add_nl;
				sprintf(crash_info, CURIMPERR4, command_text(_concur_command)); 
				c_raise_concur_exception(exception_unexpected_request);	
		}
		
	}
/*	c_concur_set_non_blocking(_concur_sock);*/
	tmp_sock = c_concur_make_client(_concur_paras[1].uval.int_val, _concur_paras[0].str_val);
	(c_set_sock)(eif_access(sep), tmp_sock);
	add_to_server_list(_concur_paras[0].str_val, _concur_paras[1].uval.int_val, tmp_sock);	
	to_register(constant_register_first_from_parent, tmp_sock, _concur_hostname, _concur_pid, _concur_paras[2].uval.int_val);

	my_eif_str = eif_wean(sep);/* free the separate object from hector */
	c_concur_set_blocking(child->sock);

/*
printf("%d Exit from Wait_sep_child after setting up <%s, %d, %d>\n", _concur_pid, child->hostname, child->pid, child->sock);
*/
	return;
}


void to_register(reg_type, s, hname, port, id)
EIF_INTEGER reg_type;
EIF_INTEGER s;
char * hname;
EIF_INTEGER port;
EIF_INTEGER id;
{
	_concur_command = reg_type;
	_concur_para_num = 3;
	adjust_parameter_array(3);
	
	_concur_paras[0].type = String_type;
	set_str_val_into_parameter(_concur_paras, hname);

	_concur_paras[1].type = Integer_type;
	_concur_paras[1].uval.int_val = port;

	_concur_paras[2].type = Integer_type;
	_concur_paras[2].uval.int_val = id;

	send_command(s);
	return;
}

/*-----------------------------------------------------------------------*/
/*                                                                       */
/*                   Utilities  for Blocked_Client_List                  */
/*                                                                       */
/*-----------------------------------------------------------------------*/

void add_to_blocked_client_queue(cli)
CLIENT *cli;
{
/* add to the end of the queue */
	cli->next = NULL;
	if (_concur_end_of_blk_cli_list == NULL) 
		_concur_blk_cli_list = cli;
	else
		_concur_end_of_blk_cli_list->next = cli;
	_concur_end_of_blk_cli_list = cli;
	(_concur_blk_cli_list_count)++;
	c_concur_set_non_blocking(cli->sock);
	unset_mask(cli->sock);
	return;
}

CLIENT *take_head_from_blocked_client_list() {
/* precondition: the list is not empty */
	CLIENT *ret;
	
	ret = _concur_blk_cli_list;
	(_concur_blk_cli_list_count)--;
	if (_concur_blk_cli_list_count == 0)
		_concur_blk_cli_list = _concur_end_of_blk_cli_list = NULL;
	else
		_concur_blk_cli_list = _concur_blk_cli_list->next;
	set_mask(ret->sock);
	return ret;
}


/*-----------------------------------------------------------------------*/
/*                                                                       */
/*                   Utilities  for Client_list                          */
/*                                                                       */
/*-----------------------------------------------------------------------*/

void add_to_client_queue(cli)
CLIENT *cli;
{
/* add to the end of the queue */
	cli->next = NULL;
	if (_concur_end_of_cli_list == NULL) 
		_concur_cli_list = cli;
	else
		_concur_end_of_cli_list->next = cli;
	_concur_end_of_cli_list = cli;
	(_concur_cli_list_count)++;
	c_concur_set_non_blocking(cli->sock);
	if (!(FD_ISSET(cli->sock, &_concur_mask))) {
		set_mask(cli->sock);
	}
	return;
}

CLIENT *take_head_from_client_list() {
/* precondition: the list is not empty */
	CLIENT *ret;
	
	ret = _concur_cli_list;
	(_concur_cli_list_count)--;
	if (_concur_cli_list_count == 0)
		_concur_cli_list = _concur_end_of_cli_list = NULL;
	else
		_concur_cli_list = _concur_cli_list->next;

	return ret;
}

void read_from_client_queue() {
	EIF_INTEGER client_num;
	EIF_INTEGER tmp;
	EIF_INTEGER sockid;
	EIF_INTEGER rc;

	client_num = _concur_cli_list_count;
	sockid = -1;
	for ( tmp=0; tmp<client_num && sockid<0; tmp++) {
		_concur_current_client = take_head_from_client_list();
		_concur_command = (_concur_current_client->req_buf).command;
		if (_concur_command != constant_not_defined) {
#ifdef DISP_MSG
printf("%d/%d ** Get a Request from BUFFER. Command %s ", _concur_pid, _concur_current_client->sock, command_text(_concur_command));
#endif
			if (_concur_command >= 0) {
				_concur_command_oid = (_concur_current_client->req_buf).command_oid;
				_concur_command_ack = (_concur_current_client->req_buf).command_ack;
				strcpy(_concur_command_class, (_concur_current_client->req_buf).command_class);
				strcpy(_concur_command_feature, (_concur_current_client->req_buf).command_feature);
#ifdef DISP_MSG
printf(" OID=%d, ACK=%d, Class=%s, Feature=%s, ", _concur_command_oid, _concur_command_ack, _concur_command_class, _concur_command_feature);
#endif
			}
			_concur_para_num = (_concur_current_client->req_buf).para_num;
			(_concur_current_client->req_buf).command = constant_not_defined;
#ifdef DISP_MSG
printf(" Para#=%d\n", _concur_para_num);
#endif
			return;	
		}

		sockid = _concur_current_client->sock;
		rc = c_try_to_get_command(sockid);
		switch (rc) {
			case -1:
				add_to_client_queue(_concur_current_client);
				_concur_current_client = NULL;
				sockid = -1;
				break;
			case -3:
				/* error happened to the client.*/
				c_concur_close_socket(_concur_current_client->sock);
				if (_concur_current_client->type == constant_normal_client) {
				/* error happened to the normal client, raise an exception */
					c_concur_close_socket(_concur_current_client->sock);
					free(_concur_current_client);
					add_nl;
					strcat(_concur_crash_info, CURAPPERR8);
					free(_concur_current_client);
					_concur_current_client = NULL;
					c_raise_concur_exception(exception_network_connection_crash);
					break;
				}
				else {
				/* error happened to the REMOTE client, so just release it */
					unregister(constant_release_all, constant_not_defined);
					free(_concur_current_client);
					_concur_current_client = NULL;
					sockid = -1;
					break;
				}
			default:
				_concur_command = c_get_command_code();
#ifdef DISP_MSG
				printf("%d/%d Got command from client queue %s ", _concur_pid, sockid, command_text(_concur_command)); 
#endif
				if (_concur_command >= 0) {
					_concur_command_oid = c_get_oid();
					strcpy(_concur_command_class, c_get_class_name());
					strcpy(_concur_command_feature, c_get_feature_name());
					_concur_command_ack = c_get_ack();
#ifdef DISP_MSG
					printf(" OID:%d, CLASS:%s, FEATURE:%s, ACK:%d ", _concur_command_oid, _concur_command_class, _concur_command_feature, _concur_command_ack);
#endif
				}
				_concur_para_num = c_get_para_num();
#ifdef DISP_MSG
				printf(" PARA#:%d\n", _concur_para_num);
#endif
		}
	}
	return;
}


/*-----------------------------------------------------------------------*/
/*                                                                       */
/*                   Utilities for server_list                           */
/*                                                                       */
/*-----------------------------------------------------------------------*/
void add_to_server_list(hname, port, sock)
char *hname;
EIF_INTEGER port;
EIF_INTEGER sock;
{
/* add to the end of the list */
	SERVER *ser;

	ser = (SERVER *)(malloc(sizeof(SERVER)));
	valid_memory(ser);
	strcpy(ser->hostname, hname);
	ser->pid = port;
	ser->sock = sock;
	ser->count = 1;
	ser->reservation = -1;

	ser->next = NULL;
	if (_concur_end_of_ser_list == NULL) 
		_concur_ser_list = ser;
	else
		_concur_end_of_ser_list->next = ser;
	_concur_end_of_ser_list = ser;
	(_concur_ser_list_count)++;
	return;
}

SERVER *take_head_from_server_list() {
/* precondition: the list is not empty */
	SERVER *ret;
	
	ret = _concur_ser_list;
	(_concur_ser_list_count)--;
	if (_concur_ser_list_count == 0)
		_concur_ser_list = _concur_end_of_ser_list = NULL;
	else
		_concur_ser_list = _concur_ser_list->next;

	return ret;
}


void release_server_list() {
	SERVER *tmp;
	
#ifdef DISP_MSG
	printf("Begin release server list:\n");
#endif
	for(; _concur_ser_list != NULL; ) {
#ifdef DISP_MSG
		printf("<host=[%s], port=%d, count=%d, sock=%d>\n", _concur_ser_list->hostname, _concur_ser_list->pid, _concur_ser_list->count, _concur_ser_list->sock);	
#endif
		/* first, cleanup all proxiies of the objects imported from 
		 * the server. But we don't free imported-objects one
		 * server by one server, we will call "releae_imported_object" 
		 * after the calling of this procedure to free them all once.
		*/
		
		
		/* Now, ask the server to cleanup all objects exported to
		 * the current processor 
		*/
		if (_concur_ser_list->sock>=0) {
		/* the server is  another processor, so send a RELESE command to it
		 * so that the server can cleanup the exported objects to the
		 * current processor
		*/
			_concur_command = constant_release;
			_concur_para_num = 0;
			send_command(_concur_ser_list->sock);
		}
		else 
		/* the server is itself, so just cleanup the exported objects to
		 * itself.
		*/
			change_ref_table_and_exported_obj_list(_concur_ser_list->hostname, _concur_ser_list->pid, constant_not_defined, constant_release_all);

		/* then, close the network connection to the server and 
		 * delete it from the server list
		*/
		c_concur_close_socket(_concur_ser_list->sock);
		tmp = take_head_from_server_list();
		free(tmp);
	}
	_concur_server_list_released = 1;

	return;
}

void release_imported_objects() {
/* Even when a separate processor terminates its execution normally,  its
 * imported object list  may still be not NULL(which depends on if it
 * has servers.
 * So, the function is called not only when crash happens to the execution
 * of an application, but also when the execution of the application
 * terminates normally.
*/
	IMPORTED_OBJ_TABLE_NODE *tmp_tab_ptr;
	PROXY_LIST_NODE *tmp_list_ptr, *tmp_list_ptr1;

	for(tmp_tab_ptr=NULL; _concur_imported_obj_tab; tmp_tab_ptr=_concur_imported_obj_tab, _concur_imported_obj_tab=_concur_imported_obj_tab->next) {
		if (tmp_tab_ptr)
			free(tmp_tab_ptr);
		for (tmp_list_ptr1=NULL, tmp_list_ptr=_concur_imported_obj_tab->list_root; tmp_list_ptr; tmp_list_ptr1=tmp_list_ptr,tmp_list_ptr=tmp_list_ptr->next) {
			if (tmp_list_ptr1)
				free(tmp_list_ptr1);
			eif_object_id_free(tmp_list_ptr->proxy_id);
		}
		if (tmp_list_ptr1)
			free(tmp_list_ptr1);
	}
	if (tmp_tab_ptr)
		free(tmp_tab_ptr);
}

void release_exported_objects() {
/* When a separate processor terminates its execution normally,  its
 * exported object list should be NULL.
 * So, the function is only called when crash happens to the execution
 * of an application.
*/
	REF_TABLE_NODE *tmp_tab_ptr;
	REF_LIST_NODE  *tmp_list_ptr, *tmp_list_ptr1;
	EXPORTED_OBJ_LIST_NODE *tmp_exp_obj;

	/* first, we free the reference table */
	for (tmp_tab_ptr = NULL; _concur_ref_table;
tmp_tab_ptr=_concur_ref_table, _concur_ref_table=_concur_ref_table->next) {
		if (tmp_tab_ptr)
			free(tmp_tab_ptr);
		for (tmp_list_ptr1=NULL, tmp_list_ptr=_concur_ref_table->ref_list; tmp_list_ptr; tmp_list_ptr1=tmp_list_ptr,tmp_list_ptr=tmp_list_ptr->next) {
            if (tmp_list_ptr1)
                free(tmp_list_ptr1);
        }
        if (tmp_list_ptr1)
            free(tmp_list_ptr1);
	}
	if (tmp_tab_ptr)
		free(tmp_tab_ptr);

	/* Now, we free exported object list, in the same time, we free the
	 * exported object from "separate_object_id_set"
	*/
	for (tmp_exp_obj = NULL; _concur_exported_obj_list; tmp_exp_obj=_concur_exported_obj_list, _concur_exported_obj_list=_concur_exported_obj_list->next) {
		if (tmp_exp_obj)
			free(tmp_exp_obj);
		eif_separate_object_id_free(_concur_exported_obj_list->oid);
	}
	if (tmp_exp_obj)
		free(tmp_exp_obj);
	return;
}

/*-----------------------------------------------------------------------*/
/*                                                                       */
/*                   Utilities  for  Child_list                          */
/*                                                                       */
/*-----------------------------------------------------------------------*/

void add_to_child_list(chi)
CHILD  *chi;
{
/* add to the end of the list */
	chi->next = NULL;
	if (_concur_end_of_child_list == NULL) 
		_concur_child_list = chi;
	else
		_concur_end_of_child_list->next = chi;
	_concur_end_of_child_list = chi;
	(_concur_child_list_count)++;
	c_concur_set_blocking(chi->sock);
	set_mask(chi->sock);
	return;
}

CHILD *take_head_from_child_list() {
/* precondition: the list is not empty */
	CHILD *ret;
	
	ret = _concur_child_list;
	(_concur_child_list_count)--;
	if (_concur_child_list_count == 0)
		_concur_child_list = _concur_end_of_child_list = NULL;
	else
		_concur_child_list = _concur_child_list->next;
	unset_mask(ret->sock);
	return ret;
}


/*-----------------------------------------------------------------------*/
/*                                                                       */
/*       Utilities for processing RUN_TIME errors                        */
/*                                                                       */
/*-----------------------------------------------------------------------*/

void wait_scoop_daemon() {
	get_cmd_data(_concur_scoop_dog->sock);
	c_close_socket(_concur_scoop_dog->sock);
	_concur_scoop_dog->sock = -2;
	free(_concur_scoop_dog);
	_concur_scoop_dog = NULL;

	if (_concur_command != constant_start_sep_obj_ok) {
		add_nl;
		strcat(_concur_crash_info, CURAPPERR9);
		c_raise_concur_exception(exception_fail_creating_sep_obj);
	}
	
	return;	
}

extern void failure();
#define tERROR_STACK

void default_rescue() {
	char err_msg[4096];
#ifdef SIGNAL
	CONCUR_RESC_START1;
#ifdef SIGPIPE
	signal(SIGPIPE, sig_def_resc);
#else
#endif
#else
	RTED;
	RTEX;
    RTSN;
/*
    RTDA;
*/
	int as_level;
    RTXD;
	RTXI(0);
	RTEA("RT-Concur1", 0, root_obj);
	RTEJ;
#endif
#ifdef nDISP_MSG
if (_concur_parent)
	printf("%d Enter DEFAULT_RESC with parent: %d\n", _concur_pid, _concur_parent->sock);
else
	printf("%d Enter DEFAULT_RESC with parent: Void\n", _concur_pid);
#endif

#ifdef ERROR_STACK
failure();
#endif
	_concur_exception_has_happened = 1;
	process_request_from_parent();
	process_request_from_child(0);
	release_child_list();
#ifdef SIGNAL
#ifdef SIGPIPE
	signal(SIGPIPE, sig_def_resc);
#else
#endif
#endif
	
	if (!_concur_paras_size) {
		int tmp_int;
	    _concur_paras_size = constant_max_para_num;
	    _concur_paras = (PARAMETER *)(malloc(_concur_paras_size * sizeof(PARAMETER)));
	    valid_memory(_concur_paras);
		for(tmp_int=0; tmp_int<_concur_paras_size; tmp_int++) 
			_concur_paras[tmp_int].str_len = 0;
	}

	if (_concur_command != constant_report_error) {
		_concur_para_num = 0;
		strcpy(err_msg, "Detected Crash Happened Here: \n    ");	
	}	
	else {
		if (_concur_parent == NULL) 
			strcpy(err_msg, "Called From(root): \n    ");
		else 
			strcpy(err_msg, "Called From: \n    ");
	}
	if (strlen(_concur_class_name_of_root_obj)) {
		strcat(err_msg, "separate object '");
		strcat(err_msg, _concur_class_name_of_root_obj);
		strcat(err_msg, "' ");
	}
	strcat(err_msg, "on host <");
	if (!_concur_pid) {
		c_get_host_name();
		_concur_pid = c_get_pid();
	}
	strcat(err_msg, _concur_hostname);
	sprintf(err_msg+strlen(err_msg), ", %d>\n", _concur_pid);
	if (strlen(_concur_crash_info)) {
		strcat(err_msg, "Error Message:\n");
		strcat(err_msg, _concur_crash_info);
		strcat(err_msg, "\n");
	}
	else {
		if (_concur_command != constant_report_error)
			if (_concur_ser_list_count)
				sprintf(err_msg+strlen(err_msg), "Error Message:\n    Error happened on the local processor or One of its SERVERs may be killed by user.\n");
			else
				sprintf(err_msg+strlen(err_msg), "Error Message:\n    Error happened on the local processor.\n");
		else
			sprintf(err_msg+strlen(err_msg), "Error Message:\n    %s\n", error_info());
	}
	strcat(err_msg, "Crash Record:");
	extend_string(&_concur_call_stack, err_msg);
	get_call_stack();

	_concur_paras[_concur_para_num].type = String_type;
	set_str_val_into_parameter(_concur_paras+_concur_para_num, _concur_call_stack.info);
	if (_concur_command != constant_report_error)
		_concur_command = constant_report_error;
	(_concur_para_num)++;	

	if (_concur_parent != NULL) {
		if (_concur_parent->sock >= 0) {
/*
printf("\n%d %s send message to its parents:\n", _concur_pid, _concur_class_name_of_root_obj);
print_run_time_error_message();
*/
			send_command(_concur_parent->sock);
			c_close_socket(_concur_parent->sock);
			_concur_parent->sock = -2;
			free(_concur_parent);
		}
		else {
			free(_concur_parent);
		}
	}
	else {
		if (_concur_root_of_the_application) {
			print_run_time_error_message();
		}
		else {
		}
	}

	release_system_lists_in_rescue();
	free_parameter_array(_concur_paras, _concur_paras_size);
	if (_concur_call_stack.info)
		free(_concur_call_stack.info);
	exit(1); 
#ifdef SIGNAL
#else
	RTXE;
	RTEE;
	RTOK;
#endif
	
printf("%d $$$$$$$$$$$$$$$$To exit from DEFAULT_RESCUE\n", _concur_pid);
	return;

rescue:
#ifdef SIGNAL
#else
	RTEU;
	RTXS(0);
#endif
	if (_concur_parent && _concur_parent->sock>=0) {
		c_close_socket(_concur_parent->sock);
		_concur_parent->sock = -3;
	}
#ifdef SIGNAL
	CONCUR_RESC_RETRY;
#else
	RTER;
#endif
}

void print_run_time_error_message() {
	EIF_INTEGER tmp;

	printf("\n*************** Error Message of Running Concurrent Application ***************\n");
	for(tmp=0; tmp<_concur_para_num; tmp++) {
		printf("%s", _concur_paras[tmp].str_val);
	    printf("\n*******************************************************************************\n");
	}
	
	return;
}

void process_request_from_parent() {
	EIF_INTEGER rc;


	if (_concur_parent != NULL) 

		if (_concur_parent->sock >= 0) {
			rc = c_try_to_get_command(_concur_parent->sock);
			switch (rc) {
				case -1:
					break;
				case -3:
					c_close_socket(_concur_parent->sock);
					_concur_parent->sock = -4;
					if (!_concur_exception_has_happened)
						default_rescue();
					break;
				default:
				/* the request from parent must be STOP_EXECUTION */
					_concur_command = c_get_command_code();
#ifdef DISP_MSG
					printf("%d/%d Got command from parent: %s", _concur_pid, _concur_parent->sock, command_text(_concur_command));
#endif
					_concur_para_num = c_get_para_num();
#ifdef DISP_MSG
					printf(" PARA#:%d\n", _concur_para_num);
#endif
					c_close_socket(_concur_parent->sock);
					_concur_parent->sock  = -5;
					if (!_concur_exception_has_happened) {
						add_nl;
						sprintf(crash_info, "    The parent processor asked the local processor to terminate.");
						default_rescue();
					}
			}
		}

	return;
}


void process_request_from_child(no_error_before) 
EIF_BOOLEAN no_error_before;
{
	EIF_INTEGER child_num;
	EIF_INTEGER tmp;
	EIF_INTEGER rc;
	CHILD *current_child;
	EIF_INTEGER tmp_cmd, tmp_para_num;

	char tmp_info[300];

#ifdef SIGNAL
	CONCUR_RESC_START2;
#ifdef SIGPIPE
	signal(SIGPIPE, sig_proc_child);
#else
#endif
#else
	RTED;
	RTEX;
    RTSN;
/*
    RTDA;
*/
	int as_level;
    RTXD;
	RTXI(0);
	RTEA("RT-Concur2", 0, root_obj);
	RTEJ;
#endif


	child_num = _concur_child_list_count;
	tmp=0; 
	for(; tmp < child_num && _concur_child_list_count > 0; tmp++) {
		current_child = take_head_from_child_list();
		rc = c_try_to_get_command(current_child->sock);
		switch (rc) {
			case -1:
				add_to_child_list(current_child);
				current_child = NULL;
				break;
			case -3:
				if (!_concur_exception_has_happened) {
					add_nl;
					sprintf(crash_info, CURAPPERR10, error_info());
					default_rescue();
				}
				break;
			default:
				tmp_cmd = c_get_command_code();
#ifdef DISP_MSG
				printf("%d/%d Got command from child queue %s ", _concur_pid, current_child->sock, command_text(tmp_cmd));
#endif
				tmp_para_num = c_get_para_num();
#ifdef DISP_MSG
				printf(" PARA#:%d\n", tmp_para_num);
#endif
				if (_concur_command != constant_report_error) {
					_concur_command = tmp_cmd;
					_concur_para_num = tmp_para_num;
					sprintf(tmp_info, "    Error happened on separate processor <%s, %d>, but\nerror happened again when the local processor(%d) try to read error message\nfrom the previous processor.", current_child->hostname, current_child->pid, _concur_pid);
					set_str_val_into_parameter(_concur_paras, tmp_info);
					get_data(current_child->sock);

				}
				switch (tmp_cmd) {
					case constant_report_error:
						if (no_error_before) {
							add_nl;
							strcat(_concur_crash_info, CURAPPERR11);
							default_rescue();
						}
						break;
					case constant_exit_ok:
						break;
					default:
						printf(" Expect REPORT_ERROR/EXIT_OK but got %s.\n", command_text(tmp_cmd));
				}
				c_close_socket(current_child->sock);
				current_child->sock  = -2;
				free(current_child);
		}
	}

#ifdef SIGNAL
	if(!_concur_exception_has_happened)
#ifdef SIGPIPE
		signal(SIGPIPE, def_res);
#else
#endif
#else
	RTXE;
	RTEE;
	RTOK;
#endif

	return;
rescue:
#ifdef SIGNAL
	CONCUR_RESC_RETRY;
#else
	RTEU;
	RTXS(0);
	RTER;
#endif
}


void release_system_lists_in_rescue() {
    SERVER *tmp;
	EIF_INTEGER sock;
	
	char send_buf[2*constant_sizeofint];
#ifdef SIGNAL
	void (*ret)(int);
	CONCUR_RESC_START3;
#ifdef SIGPIPE
	ret = signal(SIGPIPE, sig_sys_list);
#else
#endif
#else
	RTED;
	RTEX;
    RTSN;
/*
    RTDA;
*/
	int as_level;
    RTXD;
	RTXI(0);
	RTEA("RT-Concur3", 0, root_obj);
	RTEJ;
#endif

#ifdef nDISP_MSG
printf("%d Enter SYSTEM_LIST with ser#=%d, cli#=%d\n", _concur_pid, _concur_ser_list_count, _concur_cli_list_count);
#endif
    for(; _concur_ser_list != NULL; ) {
        tmp = take_head_from_server_list();
		sock = tmp->sock;
        free(tmp);
#ifdef nDISP_MSG
printf("%d free %d \n", _concur_pid, sock);
#endif
		if (sock>=0) {
		/* if sock < 0, then the server is the local processor itself. */
			*(EIF_INTEGER *)send_buf = htonl(constant_release);
			*(EIF_INTEGER *)(send_buf+constant_sizeofint) = htonl(0);
#ifdef SIGNAL
			c_my_concur_put_stream(sock, send_buf, 2*constant_sizeofint);
#else
			c_concur_put_stream(sock, send_buf, 2*constant_sizeofint);
#endif
#ifdef DISP_MSG
	        printf("%d/%d Send RELEASE (in rescue).\n", _concur_pid, sock);
#endif
	        c_concur_close_socket(sock);
		}
    }
    _concur_server_list_released = 1;

#ifdef nDISP_MSG
printf("%d Now to free clients \n", _concur_pid);
#endif

	if (_concur_current_client)  {
		add_to_client_queue(_concur_current_client);
		_concur_current_client = NULL;
	}
    for(; _concur_cli_list; ) {
        tmp = take_head_from_client_list();
		sock = tmp->sock;
        free(tmp);

		send_command(sock);

        c_concur_close_socket(sock);
    }

	release_exported_objects();
	release_imported_objects();

#ifdef SIGNAL
#else
	RTXE;
	RTEE;
	RTOK;
#endif
    return;

rescue:
#ifdef SIGNAL
	CONCUR_RESC_RETRY;
#else
	RTEU;
	RTXS(0);
	RTER;
#endif
}

void release_child_list() {
	CHILD *current_child;
	EIF_INTEGER rc;
	EIF_INTEGER tmp_cmd, tmp_para_num;
#ifdef SIGNAL
	CONCUR_RESC_START4;
#ifdef SIGPIPE
	signal(SIGPIPE, sig_rels_child);
#else
#endif
#else
	RTED;
	RTEX;
    RTSN;
	int as_level; /* RTDA;*/
    RTXD;
	RTXI(0);
	RTEA("RT-Concur14", 0, root_obj);
	RTEJ;
#endif

#ifdef DISP_MSG1
printf("%d Enter RELEASE_CHILD #: %d\n", _concur_pid, _concur_child_list_count);
#endif
	tmp_cmd = _concur_command;
	tmp_para_num = _concur_para_num;
	
	for(; _concur_child_list != NULL; ) {
		current_child = take_head_from_child_list();
		rc = c_try_to_get_command(current_child->sock);
		switch (rc) {
			case -1:
				_concur_command = constant_stop_execution;
				_concur_para_num = 0;
				send_command(current_child->sock);
				break;
			case -3:
				if (!_concur_exception_has_happened) {
					add_nl;
					sprintf(crash_info, CURAPPERR10, error_info());
					default_rescue();
				}
				break;
			default:
				/* The child must be reporting errors or exit_ok, ignore the request. */
				;
		}
		c_close_socket(current_child->sock);
		current_child->sock = -2;
		free(current_child);
	}
	
	_concur_command = tmp_cmd;
	_concur_para_num = tmp_para_num;

#ifdef SIGNAL
#else
	RTXE;
	RTEE;
	RTOK;
#endif
	return;
rescue:
	_concur_command = tmp_cmd;
	_concur_para_num = tmp_para_num;
#ifdef SIGNAL
	CONCUR_RESC_RETRY;
#else
	RTEU;
	RTXS(0);
	RTER;
#endif
}
/*-----------------------------------------------------------------------*/
/*                                                                       */
/*       Signal Handles used to process application's crash              */
/*                                                                       */
/*-----------------------------------------------------------------------*/

#ifdef SIGNAL

void sig_null_proc(int sig) {
#ifdef SIGPIPE
	printf("%d +++++++++++++++ Got SIGNAL %d (SIGPIPE=%d)\n", _concur_pid, sig, SIGPIPE);
#endif
}

void sig_def_resc(int sig) {
	int i;
#ifdef nDISP_MSG
	printf("%d $$$$$$$$$$$$$$ DEF_RESC Got SIGNAL %d(SIGPIPE=%d)\n", _concur_pid, sig, SIGPIPE);
#endif
#ifdef HAS_SIGSETMASK
	if (_concur_sys_mask != constant_invalid_signal_mask ) {
		i = sigsetmask(_concur_sys_mask);
		_concur_sys_mask = constant_invalid_signal_mask;
	}
#endif
	CONCUR_RESC_FIRE1;
}

void sig_proc_child(int sig) {
	int i;
#ifdef nDISP_MSG
	printf("%d $$$$$$$$$$$$$$ PROC_CHILD Got SIGNAL %d (SIGPIPE=%d)\n", _concur_pid, sig, SIGPIPE);
#endif
#ifdef HAS_SIGSETMASK
	if (_concur_sys_mask != constant_invalid_signal_mask ) {
		i = sigsetmask(_concur_sys_mask);
		_concur_sys_mask = constant_invalid_signal_mask;
	}
#endif
	CONCUR_RESC_FIRE2;
}

void sig_sys_list(int sig) {
	int i;
#ifdef HAS_SIGSETMASK
#ifdef nDISP_MSG
	printf("%d $$$$$$$$$$$$$$ SYS_LIST Got SIGNAL %d (SIGPIPE=%d) sys_mask=%d", _concur_pid, sig, SIGPIPE, _concur_sys_mask);
#endif
	if (_concur_sys_mask != constant_invalid_signal_mask ) {
#ifdef nDISP_MSG
		printf(" to set back sys_mask ");
#endif
		i = sigsetmask(_concur_sys_mask);
#ifdef nDISP_MSG
		printf(" newmask=%d, oldmask=%d", _concur_sys_mask, i);
#endif
#ifdef nDISP_MSG
		i = sigsetmask(_concur_sys_mask);
		printf(" newmask=%d, oldmask=%d", _concur_sys_mask, i);
#endif
		_concur_sys_mask = constant_invalid_signal_mask;
	}
#ifdef nDISP_MSG
	printf("\n");
#endif
#endif
	CONCUR_RESC_FIRE3;
}

void sig_rels_child(int sig) {
	int i;
#ifdef HAS_SIGSETMASK
#ifdef nDISP_MSG
	printf("%d $$$$$$$$$$$$$$ RELEASE_CHILD Got SIGNAL %d (SIGPIPE=%d)\n", _concur_pid, sig, SIGPIPE);
#endif
	if (_concur_sys_mask != constant_invalid_signal_mask ) {
		i = sigsetmask(_concur_sys_mask);
		_concur_sys_mask = constant_invalid_signal_mask;
	}
#endif
	CONCUR_RESC_FIRE4;
}

void def_res(int sig) {
	int i;
#ifdef nDISP_MSG
	printf("%d $$$$$$$$$$$$$$ DEF_RES Got SIGNAL %d (SIGPIPE=%d)\n", _concur_pid, sig, SIGPIPE);
#endif
#ifdef HAS_SIGSETMASK
	if (_concur_sys_mask != constant_invalid_signal_mask ) {
		i = sigsetmask(_concur_sys_mask);
		_concur_sys_mask = constant_invalid_signal_mask;
	}
#endif
	default_rescue();
	return;
}

void longjmperror() {
	printf("%d Error when call LONGJUMP.\n", _concur_pid);
	perror("ERR_MSG");
}

#endif
/*-----------------------------------------------------------------------*/
/*                                                                       */
/*                   Utilities                                           */
/*                                                                       */
/*-----------------------------------------------------------------------*/
#ifdef SIGNAL
void c_my_concur_put_int(fd, i)
EIF_INTEGER fd;
EIF_INTEGER i;
{
#ifndef EIF_WIN32
    if (write ((int)fd, (EIF_INTEGER *)&i, sizeof (EIF_INTEGER)) < 0) {
#ifdef nDISP_MSG
printf("%d ==== In my_concur_put_int, get err=%d, WOULDBLOCK=%d ", _concur_pid, errno, EWOULDBLOCK);
#endif
        if (errno != EWOULDBLOCK) {
#ifdef nDISP_MSG
printf(" To Set Mask\n");
#endif
#ifdef HAS_SIGSETMASK
			_concur_sys_mask = sigsetmask(SIGPIPE);
#endif
/*
printf(" got sys_mask=%d\n", _concur_sys_mask);
			i = kill(getpid(), SIGPIPE);
*/
		}
#ifdef nDISP_MSG
printf("\n");
#endif
	}
#else
	i = htonl(i);
    if (send (fd, (char *) &i, sizeof (EIF_INTEGER), 0) == SOCKET_ERROR)
        if (WSAGetLastError() != EWOULDBLOCK)
            eio();
#endif
}

void c_my_concur_put_stream(fd, buf, len)
EIF_INTEGER fd;
EIF_POINTER buf;
EIF_INTEGER len;
{
#ifndef EIF_WIN32
    if (write ((int)fd, buf, len) != len) {
#ifdef nDISP_MSG
printf("%d ==== In my_concur_put_stream, get err=%d, WOULDBLOCK=%d ", _concur_pid, errno, EWOULDBLOCK);
#endif
        if (errno != EWOULDBLOCK) {
#ifdef nDISP_MSG
printf(" To Set Mask\n");
#endif
#ifdef HAS_SIGSETMASK
			_concur_sys_mask = sigsetmask(SIGPIPE);
#endif
/*
printf(" got sys_mask=%d\n", _concur_sys_mask);
			i = kill(getpid(), SIGPIPE);
*/
		}
#ifdef nDISP_MSG
printf("\n");
#endif
	}
#else
    if (send (fd, buf, len, 0) == SOCKET_ERROR)
        if (WSAGetLastError() != EWOULDBLOCK)
            eio();
#endif
}
#endif


/*-----------------------------------------------------------------------*/
/*                                                                       */
/*                     Utilities for POLLING mechanism                   */
/*                                                                       */
/*-----------------------------------------------------------------------*/


EIF_INTEGER process_exception(except_mask) 
fd_set *except_mask;
{
	EIF_BOOLEAN marked=0;
	EIF_INTEGER ret=0;
	int i;
	CLIENT *cli1, *cli2;

	/* FIXME: In the following, we don't consider the exception
	 * on the socket of REMOTE CLIENT. In these cases, we should
     * just delete the REMOTE CLIENT from `client list' instead
	 * of raising an exception which causes the execution of the
	 * application to terminate. Please refer `idle_usage' in
	 * the old implementation.
	*/
	for (i=_concur_mask_limit.low; i<=_concur_mask_limit.up; i++) {
		marked = FD_ISSET(i, except_mask);
		if (marked) {
			if (_concur_current_client)
			if (_concur_current_client->type == constant_remote_client && _concur_current_client->sock == i) {
			/* There is an exception on the current client which is a
			 * remote client. In the case, just delete it.
			*/
				unregister(constant_release_all, constant_not_defined);
				marked = 0;
				ret++;
				continue;
			}
			else if (_concur_current_client->type == constant_remote_client
&& _concur_current_client->sock == i) {
			/* there is an exception on the current client which is not a
			 * remote client. In the case, raise an exception.
			*/
				add_nl;
				sprintf(crash_info, CURAPPERR8);
				_concur_current_client->sock = -2;
				free(_concur_current_client);
				_concur_current_client = NULL;
				c_raise_concur_exception(exception_network_connection_crash);	
			}

			for(cli1=_concur_cli_list, cli2=NULL; cli1; cli2=cli1,
cli1=cli1->next) {
				if (cli1->sock == i) {
					/* first, we delete the client from CLIENT LIST */
					if (cli2)
						cli2->next = cli1->next;
					else 
						_concur_cli_list = cli2->next;
					(_concur_cli_list_count)--;
					if (!_concur_cli_list)
						_concur_end_of_cli_list = NULL;
					/* Now, we process the client */
					unset_mask(cli1->sock);
					c_concur_close_socket(cli1->sock);
					if (cli1->type == constant_remote_client) {
					/* it's a REMOTE client, so just remove it from the
					 * the client list and clean up the info in reference
					 * table and exported object list.
					*/
						change_ref_table_and_exported_obj_list(cli1->hostname, cli1->pid, constant_not_defined, constant_release_all);
						cli1->sock = -2;
						free(cli1);
						cli1 = NULL;
						marked = 0;
						ret++;
						break;
					}
					else {
					/* it's a normal client, so we should terminate the
					 * execution of the application.
					*/
						add_nl;
						sprintf(crash_info, CURAPPERR8);
						cli1->sock = -2;
						free(cli1);
						cli1 = NULL;
						c_raise_concur_exception(exception_network_connection_crash);	
					}
				}
			}
			if (!marked)
				continue;
			if (_concur_sock == i) {
			/* exception happens on the server socket of the local
			 * processor.
			*/
				add_nl;
				sprintf(crash_info, "    Network exception happened on the local processor.");
				c_concur_close_socket(_concur_sock);
				c_raise_concur_exception(exception_network_connection_crash);	
			}
			if (_concur_parent)
			if (_concur_parent->sock == i) {
			/* exception happens on the parent socket of the local
			 * processor.
			*/
				add_nl;
				sprintf(crash_info, "    Network exception happened on the parent of the local processor.");
				c_concur_close_socket(_concur_sock);
				_concur_parent->sock = -2;
				c_raise_concur_exception(exception_network_connection_crash);	
			}
			/* the exception must be from the children of the local
			 * processor.
			*/
			add_nl;
			sprintf(crash_info, "    Network exception happened on the child(ren) of the local processor.");
			c_raise_concur_exception(exception_network_connection_crash);	
		}
	}

	return ret;
}



EIF_INTEGER has_msg_from_pc(read_mask) 
fd_set *read_mask;
{
	EIF_INTEGER ret=0;
	int i;
	CHILD *tmp;

	if (_concur_parent)
	if (FD_ISSET(_concur_parent->sock, read_mask))
		ret++;
	for(tmp=_concur_child_list; tmp; tmp=tmp->next) 
		if (FD_ISSET(tmp->sock, read_mask))
			ret++;
	return ret;
}


void process_connection() {
    CLIENT * recv;

	recv = (CLIENT *)(malloc(sizeof(CLIENT)));
	valid_memory(recv);
	recv->type = constant_normal_client;
	recv->count = 1;
	recv->reservation = 0;
	recv->sock = c_concur_accept(_concur_sock);
	/* we got a connection.  so get the first
	 * request from the new Client
	*/
	if (recv->sock <= 0) {
		add_nl;
		sprintf(crash_info, "Inpossible, accepted socket is %d\n", _concur_pid, recv->sock);
		c_raise_concur_exception(exception_implementation_error);
	}
	c_concur_set_blocking(recv->sock);
	directly_get_cmd_data(recv->sock);
	switch (_concur_command) {
		case constant_register:
		case constant_register_first_from_parent:
		/* we add the new client into the client list, and send
		 * back the acknowledgement for the REGISTR request
	    */
#ifdef DISP_LIST
			printf("%d Before %s(on %s from <%s, %d, %d>):\n", _concur_pid ,command_text(_concur_command), _concur_class_name_of_root_obj, CURGS(0), CURGI(1), CURGI(2));
			print_ref_table_and_exported_object();
#endif
			strcpy(recv->hostname, _concur_paras[0].str_val);
			recv->pid = _concur_paras[1].uval.int_val;
			(recv->req_buf).command = constant_not_defined;
			add_to_client_queue(recv);
			if (_concur_paras[2].uval.int_val==constant_root_oid) {
			/* the register is sent from a "remote client"
			* at first time
			*/
				recv->type = constant_remote_client;
				send_register_ack_with_root_oid(recv->sock);
			}
			else {
				if (_concur_command == constant_register)
					send_register_ack(recv->sock);
				_concur_terminatable = 1;
				change_ref_table_and_exported_obj_list(_concur_paras[0].str_val, _concur_paras[1].uval.int_val, _concur_paras[2].uval.int_val, 1);
			}
#ifdef DISP_LIST
			printf("%d After %s(on %s)\n", _concur_pid, command_text(_concur_command), _concur_class_name_of_root_obj);
			print_ref_table_and_exported_object();
#endif
			break;
		default:
			add_nl;
			sprintf(crash_info, CURAPPERR4, command_text(_concur_command), _concur_para_num);
			c_raise_concur_exception(exception_network_connection_crash);
	}
}


/*---------------------------------------------------------------* 
 *        A function called by the "dispose" of SEP_OBJ          *
 *---------------------------------------------------------------*/
void c_send_unregister_request(s, oid)
EIF_INTEGER s;
EIF_INTEGER oid;
{
	char send_buf[5*constant_sizeofint];

	*(EIF_INTEGER *)send_buf = htonl(constant_unregister);
	*(EIF_INTEGER *)(send_buf+constant_sizeofint) = htonl(1); 
	*(EIF_INTEGER *)(send_buf+2*constant_sizeofint) = htonl(Integer_type); 
	*(EIF_INTEGER *)(send_buf+3*constant_sizeofint) = htonl(constant_sizeofint);
	*(EIF_INTEGER *)(send_buf+4*constant_sizeofint) = htonl(oid); 
	c_concur_put_stream(s, send_buf, 5*constant_sizeofint);
/*
printf("%d(%s) Send UNREGISTER TO <%d> \n", _concur_pid, _concur_class_name_of_root_obj, s);
*/
	
}

/*--------------------------------------------------------------*
 *   Debug procedures                                           *
 *--------------------------------------------------------------*/
print_active_sockets() {
	int i;
	CLIENT * tmp;
	CHILD * tmpc;

	printf("%d(%s) Active Sockets(%d, %d):", _concur_pid, _concur_class_name_of_root_obj, _concur_mask_limit.low, _concur_mask_limit.up);
	for (i=_concur_mask_limit.low; i<=_concur_mask_limit.up; i++) 
		if (FD_ISSET(i, &_concur_mask)) 
			printf(" %d", i);
	printf(" blocked=%x, parent=%d, loc_ser=%d Client=", _concur_blk_cli_list, _concur_parent!=NULL?_concur_parent->sock:-1, _concur_sock);
	if (_concur_current_client)
		printf(" (%d,%d)", _concur_current_client->pid, _concur_current_client->sock);
	for(tmp=_concur_cli_list; tmp; tmp=tmp->next)
		printf(" <%d,%d>", tmp->pid, tmp->sock);
	printf(" children=");
	for(tmpc=_concur_child_list; tmpc; tmpc=tmpc->next)
		printf(" %d", tmpc->sock);
	printf("\n");
}
