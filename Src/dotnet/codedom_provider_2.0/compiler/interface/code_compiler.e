note
	description: "Eiffel compiler CodeDom interface implementation"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$$"
	revision: "$$"

class
	CODE_COMPILER

inherit
	SYSTEM_DLL_ICODE_COMPILER
	CODE_DOM_PATH
	CODE_CONFIGURATION
	CODE_SHARED_CONTEXT
	CODE_FILE_HANDLER
	CODE_EXECUTION_ENVIRONMENT
	CODE_SHARED_TEMPORARY_FILES
	CODE_SHARED_EVENT_MANAGER
	CODE_SHARED_REFERENCED_ASSEMBLIES
	CODE_SHARED_GENERATION_HELPERS
	CODE_SHARED_ACCESS_MUTEX
	CONF_ACCESS
	CODE_PROJECT_CONTEXT
	CODE_SHARED_BACKUP

create
	default_create

feature -- Access

	last_compilation_results: SYSTEM_DLL_COMPILER_RESULTS
			-- Last compilation results

	is_initialized: BOOLEAN
			-- Is compiler correctly initialized?

feature -- Basic Operations

	compile_assembly_from_source (a_options: SYSTEM_DLL_COMPILER_PARAMETERS; a_source: SYSTEM_STRING): SYSTEM_DLL_COMPILER_RESULTS
			-- Compile assembly from string `a_source' using compiler options `a_options'.
		require else
			non_void_options: a_options /= Void
			non_void_source: a_source /= Void
		local
			l_res: SYSTEM_OBJECT
		do
			if Access_mutex.wait_one then
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Starting CodeCompiler.CompileAssemblyFromSource"])
				(create {SECURITY_PERMISSION}.make ({SECURITY_PERMISSION_FLAG}.unmanaged_code)).assert
				initialize (a_options)
				if is_initialized then
					source_generator.generate (a_source)
					compile
					Result := last_compilation_results
				else
					create Result.make (a_options.temp_files)
					l_res := Result.errors.add (create {SYSTEM_DLL_COMPILER_ERROR}.make_with_file_name ("", 0, 0, "0", "Compiler initialization failed (1)"))
				end
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Ending CodeCompiler.CompileAssemblyFromSource"])
				Access_mutex.release_mutex
			end
		ensure then
			non_void_results: Result /= Void
		rescue
			Access_mutex.release_mutex
			Event_manager.process_exception
		end

	compile_assembly_from_source_batch (a_options: SYSTEM_DLL_COMPILER_PARAMETERS; a_sources: NATIVE_ARRAY [SYSTEM_STRING]): SYSTEM_DLL_COMPILER_RESULTS
			-- Compile assembly from strings in array `a_sources' using compiler options `a_options'.
		require else
			non_void_options: a_options /= Void
			non_void_sources: a_sources /= Void
		local
			i, l_count: INTEGER
			l_res: SYSTEM_OBJECT
		do
			if Access_mutex.wait_one then
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Starting CodeCompiler.CompileAssemblyFromSourceBatch"])
				(create {SECURITY_PERMISSION}.make ({SECURITY_PERMISSION_FLAG}.unmanaged_code)).assert
				initialize (a_options)
				if is_initialized then
					from
						l_count := a_sources.count
					until
						i = l_count
					loop
						source_generator.generate (a_sources.item (i))
						i := i + 1
					end
					compile
					Result := last_compilation_results
				else
					create Result.make (a_options.temp_files)
					l_res := Result.errors.add (create {SYSTEM_DLL_COMPILER_ERROR}.make_with_file_name ("", 0, 0, "0", "Compiler initialization failed (2)"))
				end
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Ending CodeCompiler.CompileAssemblyFromSourceBatch"])
				Access_mutex.release_mutex
			end
		ensure then
			non_void_results: Result /= Void
		rescue
			Access_mutex.release_mutex
			Event_manager.process_exception
		end

	compile_assembly_from_file (a_options: SYSTEM_DLL_COMPILER_PARAMETERS; a_file_name: SYSTEM_STRING): SYSTEM_DLL_COMPILER_RESULTS
			-- Compile assembly from file `a_file_name' using compiler options `a_options'.
		require else
			non_void_options: a_options /= Void
			non_void_file_name: a_file_name /= Void
		local
			l_res: SYSTEM_OBJECT
		do
			if Access_mutex.wait_one then
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Starting CodeCompiler.CompileAssemblyFromFile"])
				(create {SECURITY_PERMISSION}.make ({SECURITY_PERMISSION_FLAG}.unmanaged_code)).assert
				if (create {RAW_FILE}.make (a_file_name)).exists then
					Result := compile_assembly_from_source (a_options, file_content (a_file_name))
				else
					create Result.make (a_options.temp_files)
					l_res := Result.errors.add (create {SYSTEM_DLL_COMPILER_ERROR}.make_with_file_name ("", 0, 0, "0", "Source file is missing"))
					Event_manager.raise_event ({CODE_EVENTS_IDS}.Missing_source_file, [a_file_name])
				end
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Ending CodeCompiler.CompileAssemblyFromFile"])
				Access_mutex.release_mutex
			end
		ensure then
			non_void_results: Result /= Void
		rescue
			Access_mutex.release_mutex
			Event_manager.process_exception
		end

	compile_assembly_from_file_batch (a_options: SYSTEM_DLL_COMPILER_PARAMETERS; a_file_names: NATIVE_ARRAY [SYSTEM_STRING]): SYSTEM_DLL_COMPILER_RESULTS
			-- Compiles an assembly based on the specified `a_options' and `file_names'.
		require else
			non_void_options: a_options /= Void
			non_void_file_names: a_file_names /= Void
		local
			i, l_count: INTEGER
			l_file_name: STRING
			l_res: SYSTEM_OBJECT
		do
			if Access_mutex.wait_one then
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Starting CodeCompiler.CompileAssemblyFromFileBatch"])
				(create {SECURITY_PERMISSION}.make ({SECURITY_PERMISSION_FLAG}.unmanaged_code)).assert
				initialize (a_options)
				if is_initialized then
					from
						l_count := a_file_names.count
					until
						i = l_count
					loop
						l_file_name := a_file_names.item (i)
						if (create {RAW_FILE}.make (l_file_name)).exists then
							source_generator.generate (file_content (l_file_name))
						else
							Event_manager.raise_event ({CODE_EVENTS_IDS}.Missing_source_file, [a_file_names.item (i)])
						end
						i := i + 1
					end
					compile
					Result := last_compilation_results;
				else
					create Result.make (a_options.temp_files)
					l_res := Result.errors.add (create {SYSTEM_DLL_COMPILER_ERROR}.make_with_file_name ("", 0, 0, "0", "Compiler initialization failed (3)"))
				end
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Ending CodeCompiler.CompileAssemblyFromFileBatch"])
				Access_mutex.release_mutex
			end
		ensure then
			non_void_results: Result /= Void
		rescue
			Access_mutex.release_mutex
			Event_manager.process_exception
		end

	compile_assembly_from_dom (a_options: SYSTEM_DLL_COMPILER_PARAMETERS; a_compilation_unit: SYSTEM_DLL_CODE_COMPILE_UNIT): SYSTEM_DLL_COMPILER_RESULTS
			-- Creates an assembly based on the specified `a_options' and `a_compilation_unit' (the text to compile).
		require else
			non_void_options: a_options /= Void
			non_void_compilation_unit: a_compilation_unit /= Void
		local
			l_stream: FILE_STREAM
			l_writer: STREAM_WRITER
			l_path: SYSTEM_STRING
		do
			if Access_mutex.wait_one then
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Starting CodeCompiler.CompileAssemblyFromDom"])
				(create {SECURITY_PERMISSION}.make ({SECURITY_PERMISSION_FLAG}.unmanaged_code)).assert
				l_path := temp_files.add_extension ("es")
				create l_stream.make (l_path, {FILE_MODE}.Create_, {FILE_ACCESS}.Write, {FILE_SHARE}.Write)
				create l_writer.make (l_stream)
				(create {CODE_GENERATOR}).generate_code_from_compile_unit (a_compilation_unit, l_writer, Code_generator_options)
				l_writer.flush
				l_writer.close
				l_stream.close
				Result := compile_assembly_from_file (a_options, l_path)
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Ending CodeCompiler.CompileAssemblyFromDom"])
				Access_mutex.release_mutex
			end
		ensure then
			non_void_results: Result /= Void
		rescue
			Access_mutex.release_mutex
			Event_manager.process_exception
			if l_stream /= Void then
				l_stream.close
			end
		end

	compile_assembly_from_dom_batch (a_options: SYSTEM_DLL_COMPILER_PARAMETERS; a_compilation_units: NATIVE_ARRAY [SYSTEM_DLL_CODE_COMPILE_UNIT]): SYSTEM_DLL_COMPILER_RESULTS
			-- Compiles an assembly based on the specified a_options.
		require else
			non_void_options: a_options /= Void
			non_void_compilation_units: a_compilation_units /= Void
		local
			l_stream: FILE_STREAM
			l_writer: STREAM_WRITER
			l_paths: NATIVE_ARRAY [SYSTEM_STRING]
			l_path: SYSTEM_STRING
			i, l_count: INTEGER
		do
			if Access_mutex.wait_one then
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Starting CodeCompiler.CompileAssemblyFromDomBatch"])
				(create {SECURITY_PERMISSION}.make ({SECURITY_PERMISSION_FLAG}.unmanaged_code)).assert
				from
					l_count := a_compilation_units.length
					create l_paths.make (l_count)
				until
					i = l_count
				loop
					l_path := temp_files.add_extension (i.out + ".es")
					l_paths.put (i, l_path)
					create l_stream.make (l_path, {FILE_MODE}.Create_, {FILE_ACCESS}.Write, {FILE_SHARE}.Write)
					create l_writer.make (l_stream)
					(create {CODE_GENERATOR}).generate_code_from_compile_unit (a_compilation_units.item (i), l_writer, Code_generator_options)
					l_writer.flush
					l_writer.close
					l_stream.close
					i := i + 1
				end
				Result := compile_assembly_from_file_batch (a_options, l_paths)
				Event_manager.raise_event ({CODE_EVENTS_IDS}.log, ["Ending CodeCompiler.CompileAssemblyFromDomBatch"])
				Access_mutex.release_mutex
			end
		ensure then
			non_void_results: Result /= Void
		rescue
			Access_mutex.release_mutex
			Event_manager.process_exception
			if l_stream /= Void then
				l_stream.close
			end
		end

feature {NONE} -- Implementation

	initialize (a_options: SYSTEM_DLL_COMPILER_PARAMETERS)
			-- Initialize compilation settings from `a_options'.
		require
			non_void_options: a_options /= Void
		local
			l_temp_dir, l_root_class, l_system_name, l_resource_file,
				l_path, l_assembly_file_name, l_creation_routine, l_precompile_file: STRING
			l_res: DIRECTORY_INFO
			l_retried: BOOLEAN
			l_assemblies: SYSTEM_DLL_STRING_COLLECTION
			i, l_count: INTEGER
			l_assembly: CODE_REFERENCED_ASSEMBLY
			l_type: CODE_GENERATED_TYPE
			l_creation_routines: HASH_TABLE [CODE_CREATION_ROUTINE, STRING]
			l_arguments: LIST [CODE_PARAMETER_DECLARATION_EXPRESSION]
			l_found: BOOLEAN
			l_system: CONF_SYSTEM
			l_cluster: CONF_CLUSTER
			l_precompiler: CODE_PRECOMPILER
			l_precompile_assemblies: NATIVE_ARRAY [ASSEMBLY_NAME]
			l_references_list: CODE_REFERENCES_LIST
			l_assembly_name, l_name: ASSEMBLY_NAME
			l_target: CONF_TARGET
			l_root: CONF_ROOT
			l_option: CONF_OPTION
			l_library: CONF_LIBRARY
			l_conf_asm: CONF_ASSEMBLY
			l_factory: CONF_FACTORY
		do
			if not l_retried then
				-- First create temporary directory if needed
				if a_options.temp_files = Void or else a_options.temp_files.temp_dir = Void or else a_options.temp_files.temp_dir.length = 0 then
					Event_manager.raise_event ({CODE_EVENTS_IDS}.Missing_temporary_files, [])
					set_temp_files (create {SYSTEM_DLL_TEMP_FILE_COLLECTION}.make_from_temp_dir ({PATH}.get_temp_path))
				else
					set_temp_files (a_options.temp_files)
				end

				l_temp_dir := temp_files.temp_dir
				if l_temp_dir.item (l_temp_dir.count) = Directory_separator then
					l_temp_dir.keep_head (l_temp_dir.count - 1)
				end
				if not {SYSTEM_DIRECTORY}.exists (l_temp_dir) then
					l_res := {SYSTEM_DIRECTORY}.create_directory (l_temp_dir)
				end

				-- Initialize `compilation_directory' and `source_generator'
				compilation_directory := l_temp_dir
				create source_generator.make (compilation_directory)

				-- Finally initialize compiler
 				ace_file_path := temp_files.add_extension ("ecf")

				if a_options.output_assembly /= Void then
					system_path := a_options.output_assembly
				end
				if system_path = Void or else system_path.is_empty then
					if a_options.generate_executable then
						system_path := temp_files.add_extension ("exe")
					else
						system_path := temp_files.add_extension ("dll")
					end
				end
				l_system_name := system_path.substring (system_path.last_index_of (Directory_separator, system_path.count) + 1, system_path.count)
				if l_system_name.substring_index (".dll", 1) = l_system_name.count - 3 or l_system_name.substring_index (".exe", 1) = l_system_name.count - 3 then
					l_system_name.keep_head (l_system_name.count - 4)
				end
				create l_factory
				l_system := l_factory.new_system (l_system_name, (create {UUID_GENERATOR}).generate_uuid)
				l_target := l_factory.new_target (Target_name, l_system)
				l_system.add_target (l_target)
				l_cluster := l_factory.new_cluster ("root_cluster", create {CONF_DIRECTORY_LOCATION}.make (compilation_directory, l_target), l_target)
				if Compilation_context.namespace /= Void then
					l_cluster.changeable_internal_options.set_local_namespace (Compilation_context.namespace)
				end
				l_target.add_cluster (l_cluster)

				l_root_class := Compilation_context.root_class_name
				l_creation_routine := Compilation_context.root_creation_routine_name
				if l_root_class = Void or else l_root_class.is_empty then
					if a_options.main_class /= Void then
						l_root_class := a_options.main_class
					end
					if l_root_class = Void or else l_root_class.is_empty then
						if not Resolver.generated_types.is_empty then
							from
								Resolver.generated_types.start
								l_type := Resolver.generated_types.item_for_iteration
								l_root_class := l_type.eiffel_name
								from
									l_creation_routines := l_type.creation_routines
									l_creation_routines.start
								until
									l_creation_routines.after or l_found
								loop
									l_arguments := l_creation_routines.item_for_iteration.arguments
									l_found := l_arguments = Void or else l_arguments.is_empty
									if l_found then
										l_creation_routine := l_creation_routines.item_for_iteration.eiffel_name
									end
									l_type.creation_routines.forth
								end
								Resolver.generated_types.forth
							until
								Resolver.generated_types.after
							loop
								l_cluster.add_visible (Resolver.generated_types.item_for_iteration.eiffel_name, Void, Void, Void)
								Resolver.generated_types.forth
							end
						else
							l_root_class := default_root_class
						end
					end
				end

				if not l_root_class.is_equal ("ANY") and not l_root_class.is_equal ("NONE") and l_creation_routine /= Void then
					create l_root.make ("root_cluster", l_root_class, l_creation_routine, false)
				else
					create l_root.make ("root_cluster", l_root_class, Void, false)
				end
				l_target.set_root (l_root)

				if a_options.generate_executable then
					l_target.add_setting ("console_application", "true")
				else
					l_target.add_setting ("console_application", "false")
				end
				l_target.add_setting ("msil_generation", "true")
				l_target.add_setting ("msil_generation_type", "dll")
				l_target.add_setting ("msil_clr_version", Clr_version)
				l_target.add_setting ("dotnet_naming_convention", "true")

				-- Setup Precompile
				l_precompile_file := Compilation_context.precompile_file
					-- Was there a snippet defined precompile file?
				if l_precompile_file = Void then
					l_precompile_file := precompile_ace_file
						-- Otherwise use configuration precompile file
				end
				if l_precompile_file /= Void then
					create l_precompiler.make (l_precompile_file, precompile_cache)
					l_precompiler.precompile
					if l_precompiler.successful then
						l_target.set_precompile (l_factory.new_precompile ("default", l_precompiler.configuration_path, l_target))
					else
						Event_manager.raise_event ({CODE_EVENTS_IDS}.Precompile_failed, [l_precompile_file, precompile_cache])
					end
				end

				-- Setup referenced assemblies
				l_assemblies := a_options.referenced_assemblies
				if l_assemblies /= Void and then l_assemblies.count > 0 then
					from
						l_count := l_assemblies.count
						i := 0
					until
						i = l_count
					loop
						l_assembly_file_name := l_assemblies.item (i)
						if not Referenced_assemblies.has_file (l_assembly_file_name) then
							if {SYSTEM_FILE}.exists (l_assembly_file_name) then
								l_path := l_assembly_file_name
							else
								l_path := {RUNTIME_ENVIRONMENT}.get_runtime_directory
								l_path.append (l_assembly_file_name)
							end
							if {SYSTEM_FILE}.exists (l_path) then
								Referenced_assemblies.extend_file (l_path)
							else
								Event_manager.raise_event ({CODE_EVENTS_IDS}.Missing_assembly, [l_assembly_file_name])
							end
						end
						i := i + 1
					end
				else
					add_default_assemblies
				end

				-- Add base library
				l_library := l_factory.new_library ("base", "$ISE_LIBRARY/library/base/base.ecf", l_target)
				create l_option
				l_option.set_local_namespace ("EiffelSoftware.Library.Base")
				l_library.set_options (l_option)
				l_target.add_library (l_library)

				-- Add referenced assemblies
				from
					Referenced_assemblies.start
				until
					Referenced_assemblies.after
				loop
					l_assembly := Referenced_assemblies.item
					l_conf_asm := l_factory.new_assembly (l_assembly.cluster_name, l_assembly.assembly.location, l_target)
					l_conf_asm.set_name_prefix (l_assembly.assembly_prefix)
					l_target.add_assembly (l_conf_asm)
					Referenced_assemblies.forth
				end

				-- Setup resource file
				if a_options.win_32_resource /= Void then
					l_resource_file := compilation_directory + Directory_separator.out + l_system_name + ".rc"
					copy_file (a_options.win_32_resource, l_resource_file)
					if last_copy_successful then
						temp_files.add_file (l_resource_file, False)
					end
				end

				-- Setup miscelleaneous settings
				if compiler_metadata_cache /= Void then
					l_target.add_setting ("metadata_cache_path", compiler_metadata_cache)
				end

				if a_options.include_debug_information then
					l_target.add_setting ("line_generation", "true")
				end

				l_system.set_file_name (ace_file_path)
				l_system.store
				if l_system.store_successful then
					backup.backup_file_from_path (ace_file_path)
					load_result_in_memory := a_options.generate_in_memory
					cleanup -- to avoid error if a .epr file already exists in project folder
					is_initialized := True
				else
					Event_manager.raise_event ({CODE_EVENTS_IDS}.Failed_config_save, [ace_file_path])
				end
			end
		ensure
			non_void_temp_files: is_initialized implies temp_files /= Void
			valid_compilation_directory: is_initialized implies compilation_directory /= Void and then (create {DIRECTORY}.make (compilation_directory)).exists
			non_void_source_generator: is_initialized implies source_generator /= Void
			non_void_system_path: is_initialized implies system_path /= Void
			valid_system_path: is_initialized implies not system_path.is_empty
		rescue
			l_retried := True
			retry
		end

	compile
			-- Compile all `.e' files in directory `compilation_directory'.
			-- Put resulting dlls and pdb in `system_path' folder.
		require
			ace_file_set: ace_file_path /= Void
		local
			l_retried: BOOLEAN
			l_start_info: SYSTEM_DLL_PROCESS_START_INFO
			l_process: SYSTEM_DLL_PROCESS
			l_output_reader, l_error_reader: SYSTEM_THREAD
			l_res: SYSTEM_OBJECT
			l_compiler_path: STRING
		do
			if not l_retried then
				create last_compilation_results.make (temp_files)
				l_compiler_path := Compiler_path
				if l_compiler_path = Void then
					Event_manager.raise_event ({CODE_EVENTS_IDS}.Missing_compiler_path, [])
				else
					create l_start_info.make_from_file_name_and_arguments (l_compiler_path + Directory_separator.out + Compiler_file_name, "-batch -finalize -ace %"" + ace_file_name + "%"")
					l_start_info.set_working_directory (compilation_directory)
					l_start_info.set_create_no_window (True)
					l_start_info.set_redirect_standard_error (True)
					l_start_info.set_redirect_standard_output (True)
					l_start_info.set_use_shell_execute (False)
					create l_process.make
					l_process.set_start_info (l_start_info)
					if l_process.start then
						output_stream := l_process.standard_output
						error_stream := l_process.standard_error
						create l_output_reader.make (create {THREAD_START}.make (Current, $read_output))
						create l_error_reader.make (create {THREAD_START}.make (Current, $read_error))
						l_output_reader.start
						l_error_reader.start
						l_process.wait_for_exit
						l_output_reader.join
						l_error_reader.join
						if compiler_error /= Void then
	--						l_res := last_compilation_results.errors.add (create {SYSTEM_DLL_COMPILER_ERROR}.make ("", 0, 0, "", compiler_error))					
							l_res := last_compilation_results.output.add (compiler_error)
							Event_manager.raise_event ({CODE_EVENTS_IDS}.Compiler_output, [compiler_error])
						end
						if compiler_output /= Void then
							l_res := last_compilation_results.output.add (compiler_output)
						end
						check_compilation_result
					end
					cleanup
					reset_temp_files
				end
				ace_file_path := Void
				source_generator := Void
				compilation_directory := Void
			end
		ensure
			non_void_results: last_compilation_results /= Void
		end

	check_compilation_result
			-- Check that assembly was created.
			-- Set native compiler result and compiled assembly accordingly.
		local
			l_retried: BOOLEAN
			l_dir_name, l_system_dir, l_file: STRING
			l_dir: DIRECTORY
			l_files: LIST [STRING]
			l_file_stream: FILE_STREAM
			l_array: NATIVE_ARRAY [NATURAL_8]
			l_ass: RAW_FILE
			l_res: SYSTEM_OBJECT
		do
			if not l_retried then
				last_compilation_results.set_native_compiler_return_value (1)
				l_dir_name := default_f_code_path (compilation_directory)
				create l_dir.make (l_dir_name)
				if l_dir.exists then
					l_system_dir := system_path.substring (1, system_path.last_index_of (Directory_separator, system_path.count) - 1)
					if l_system_dir.is_empty then
						l_system_dir := (create {EXECUTION_ENVIRONMENT}).Current_working_directory
					end
					if not l_system_dir.is_equal (l_dir_name) then
						l_files := l_dir.linear_representation
						from
							l_files.start
						until
							l_files.after
						loop
							l_file := l_files.item
							if has_extension (l_file, "dll") or has_extension (l_file, "exe") or has_extension (l_file, "pdb") then
								copy_file (l_dir_name + Directory_separator.out + l_file, l_system_dir + Directory_separator.out + l_file)
							end
							l_files.forth
						end
						create l_ass.make (system_path)
						if l_ass.exists then
							last_compilation_results.set_path_to_assembly (system_path)
							last_compilation_results.set_native_compiler_return_value (0)
							if load_result_in_memory then
								create l_file_stream.make (system_path, {FILE_MODE}.Open, {FILE_ACCESS}.Read, {FILE_SHARE}.Read)
								create l_array.make (l_file_stream.length.to_integer)
								last_compilation_results.set_compiled_assembly ({ASSEMBLY}.load (l_array, Void))
								l_file_stream.close
							end
						end
					end
				else
					Event_manager.raise_event ({CODE_EVENTS_IDS}.Missing_directory, [l_dir_name])
				end
			else
				create last_compilation_results.make (temp_files)
				l_res := last_compilation_results.errors.add (create {SYSTEM_DLL_COMPILER_ERROR}.make_with_file_name ("", 0, 0, "1", "Compiler threw an exception"))
			end
		rescue
			l_retried := True
			retry
		end

	cleanup
			-- Cleanup compiler generated temporary files (EIFGENs directory and .epr file)
		local
			l_dir: DIRECTORY
			l_dir_name: STRING
			l_retried: BOOLEAN
			l_files: LIST [STRING]
		do
			if not l_retried then
				create l_dir_name.make (compilation_directory.count + 7)
				l_dir_name.append (compilation_directory)
				l_dir_name.append_character ((create {OPERATING_ENVIRONMENT}).Directory_separator)
				l_dir_name.append ("EIFGENs")
				create l_dir.make (l_dir_name)
				if l_dir.exists then
					l_dir.recursive_delete
				end
				create l_dir.make (compilation_directory)
				if l_dir.exists then
					l_files := l_dir.linear_representation
					from
						l_files.start
					until
						l_files.after
					loop
						if l_files.item.substring (l_files.count - 3, l_files.count).is_equal (".epr") then
							(create {RAW_FILE}.make (l_files.item)).delete
						end
						l_files.forth
					end
				end
			else
				Event_manager.raise_event ({CODE_EVENTS_IDS}.File_lock, ["compiler temporary files cleanup", l_dir_name])
			end
		rescue
			l_retried := True
			retry
		end

	read_output
			-- Read output from `output_stream'.
			-- Set result in `compiler_output'.
		require
			non_void_output_stream: output_stream /= Void
		do
			compiler_output := output_stream.read_to_end
		end

	read_error
			-- Read output from `error_stream'.
			-- Set result in `compiler_error'.
		require
			non_void_output_stream: error_stream /= Void
		do
			compiler_error := error_stream.read_to_end
		end

	file_content (a_file_name: STRING): STRING
			-- Content of file `a_file_name', encoding can be Unicode UTF-16.
		require
			attached_file_name: a_file_name /= Void
		local
			l_reader: STREAM_READER
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_reader.make_from_path (a_file_name)
				Result := l_reader.read_to_end
			end
		ensure
			attached_content: Result /= Void
		rescue
			l_retried := True
			Result := ""
			retry
		end

feature {NONE} -- Private access

	Code_generator_options: SYSTEM_DLL_CODE_GENERATOR_OPTIONS
			-- Options used by code generator to generate
			-- code to be compiled from Codedom compile unit
		once
			create Result.make
			Result.set_blank_lines_between_members (True)
			Result.set_else_on_closing (False)
			Result.set_indent_string ("%T")
		end

	source_generator: CODE_EIFFEL_SOURCE_FILES_GENERATOR
			-- Eiffel source files generator

	compilation_directory: STRING
			-- Compilation directory path

	system_path: STRING
			-- Path to compiled assembly

	load_result_in_memory: BOOLEAN
			-- Should compiled assembly be loaded in memory?

	ace_file_path: STRING
			-- Path to generated ace file

	ace_file_name: STRING
			-- Ace file name
		local
			l_index: INTEGER
		do
			if ace_file_path /= Void then
				l_index := ace_file_path.last_index_of (Directory_separator, ace_file_path.count)
				if l_index > 0 then
					Result := ace_file_path.substring (l_index + 1, ace_file_path.count)
				else
					Result := ace_file_path.twin
				end
			end
		ensure
			exists_iff_path_exists: (ace_file_path = Void) = (Result = Void)
		end

	output_stream, error_stream: STREAM_READER
			-- Compiler process output and error streams

	compiler_error, compiler_output: STRING;
			-- Compiler output and error if any

note
	copyright:	"Copyright (c) 1984-2006, Eiffel Software"
	license:	"GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options:	"http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.
			
			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).
			
			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful,	but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the	GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA
		]"
	source: "[
			 Eiffel Software
			 356 Storke Road, Goleta, CA 93117 USA
			 Telephone 805-685-1006, Fax 805-685-6869
			 Website http://www.eiffel.com
			 Customer support http://support.eiffel.com
		]"
end -- class CODE_COMPILER

