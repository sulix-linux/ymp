public int run_sandbox_main(string[] args){
    if(usr_is_merged()){
        error_add("Sandbox operation with usrmerge is not allowed!");
        error(31);
    }
    if(!get_bool("no-net")){
        sandbox_network = true;
    }
    sandbox_shared = get_value("shared");
    sandbox_rootfs = get_destdir();
    sandbox_uid = int.parse(get_value("uid"));
    sandbox_gid = int.parse(get_value("gid"));
    debug("Execute sandbox :"+join(" ",args));
    int status = sandbox(args);
    return status/256;
}

void run_sandbox_init(){
    var h = new helpmsg();
    h.name = "sandbox";
    h.minargs=1;
    h.description = "Start sandbox environment.";
    h.add_parameter("--shared","select shared directory");
    h.add_parameter("--no-net","block network access");
    add_operation(run_sandbox_main,{"sandbox", "sb"},h);
}
