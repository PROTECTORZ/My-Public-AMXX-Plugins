#include <amxmodx>

public plugin_init()
{
	register_plugin("Simple Console Print", "1.0", "PROTECTOR")

	server_print(" ")
	server_print("================================================================================")
	server_print("^tSERVER NAME")
	server_print("^tIP:")
	server_print("^tDiscord Link")
	server_print("^tOwner nick")
	server_print("^tWebsite:")
	server_print("================================================================================")
	server_print(" ")
}