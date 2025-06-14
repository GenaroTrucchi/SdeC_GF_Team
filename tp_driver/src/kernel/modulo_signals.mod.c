#include <linux/module.h>
#include <linux/export-internal.h>
#include <linux/compiler.h>

MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};



static const struct modversion_info ____versions[]
__used __section("__versions") = {
	{ 0x13c49cc2, "_copy_from_user" },
	{ 0xf0fdf6cb, "__stack_chk_fail" },
	{ 0x656e4a6e, "snprintf" },
	{ 0x88db9f48, "__check_object_size" },
	{ 0x6b10bee1, "_copy_to_user" },
	{ 0xc8b31d67, "__register_chrdev" },
	{ 0x9a29ffb6, "class_create" },
	{ 0x6bc3fbc0, "__unregister_chrdev" },
	{ 0xbe58939f, "device_create" },
	{ 0x10bf98ae, "class_destroy" },
	{ 0xc6f46339, "init_timer_key" },
	{ 0x82ee90dc, "timer_delete_sync" },
	{ 0xe6d3ff51, "device_destroy" },
	{ 0xbdfb6dbb, "__fentry__" },
	{ 0x15ba50a6, "jiffies" },
	{ 0xc38c83b8, "mod_timer" },
	{ 0x92997ed8, "_printk" },
	{ 0x5b8239ca, "__x86_return_thunk" },
	{ 0x9a3c56a9, "module_layout" },
};

MODULE_INFO(depends, "");

