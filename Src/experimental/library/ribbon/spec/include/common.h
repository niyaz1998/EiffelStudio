#ifndef _COMMON_H_
#define _COMMON_H_
#include <windows.h>
#include <ObjBase.h>
#include <initguid.h>
#include <Uiribbon.h>
//#include "resource.h"

DEFINE_GUID(IID_IUIFRAMEWORK, 0xf4f0385d, 0x6872, 0x43a8, 0xad, 0x09, 0x4c, 0x33, 0x9c, 0xb3, 0xf5, 0xc5);
DEFINE_GUID(IID_IUIAPPLICATION, 0xd428903c, 0x729a, 0x491d, 0x91, 0x0d, 0x68, 0x2a, 0x08, 0xff, 0x25, 0x22);
DEFINE_GUID(IID_IUICommandHandler, 0xefc7bdf, 0x1fdc, 0x487a, 0xbc, 0x9b, 0x24, 0xcd, 0x19, 0x29, 0x1a, 0x17);// {0EFC7BDF-1FDC-487a-BC9B-24CD19291A17} generated by ourself
DEFINE_GUID(IID_IUIRIBBON, 0x803982ab, 0x370a, 0x4f7e, 0xa9, 0xe7, 0x87, 0x84, 0x03, 0x6a, 0x6e, 0x26);//("803982ab-370a-4f7e-a9e7-8784036a6e26"))
DEFINE_GUID(IID_IUImage, 0x23c8c838, 0x4de6, 0x436b, 0xab, 0x01, 0x55, 0x54, 0xbb, 0x7c, 0x30, 0xdd);//("23c8c838-4de6-436b-ab01-5554bb7c30dd"))
DEFINE_GUID(IID_IUIImageFromBitmap, 0x18aba7f3, 0x4c1c, 0x4ba2, 0xbf, 0x6c, 0xf5, 0xc3, 0x32, 0x6f, 0xa8, 0x16);//"18aba7f3-4c1c-4ba2-bf6c-f5c3326fa816"
DEFINE_GUID(IID_IUICollection, 0xdf4f45bf, 0x6f9d, 0x4dd7, 0x9d, 0x68, 0xd8, 0xf9, 0xcd, 0x18, 0xc4, 0xdb);//"df4f45bf-6f9d-4dd7-9d68-d8f9cd18c4db"
DEFINE_GUID(IID_IUISimplePropertySet, 0xc205bb48, 0x5b1c, 0x4219, 0xa1, 0x06, 0x15, 0xbd, 0x0a, 0x5f, 0x24, 0xe2);//c205bb48-5b1c-4219-a106-15bd0a5f24e2

#endif

#ifdef __cplusplus
extern "C" {
#endif

extern HRESULT SHStrDupW_eiffel(LPCWSTR src, LPWSTR * dest);
EIF_POINTER c_create_ui_command_handler (EIF_POINTER a_commandHandler);
extern IUIFramework *g_pFramework;
extern EIF_POINTER InitializeFramework(HWND hWnd, EIF_POINTER a_ribbon_resource_handle);
extern IUIApplication *GetUIApplication();
extern BOOL CreateIUIImageFromBitmap (HBITMAP bitmap, IUIImage **image);
extern HRESULT QueryInterfaceIUICollectionWithPropVariant (PROPVARIANT * a_prop_variant);
extern IUICollection * GetUICollection ();

#ifdef __cplusplus
}
#endif
