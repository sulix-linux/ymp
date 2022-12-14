
void main(string[] args){
    // init ymp
    Ymp ymp = ymp_init(args);
    print("Ymp test");
    set_destdir("../test/example/rootfs");
    ymp.add_process("init",{"hello","world"});
    ymp.run();

    //yesno test
    print("Interface test");
    yesno("Yes or no");

    // archive test
    print("Archive test");
    var tar = new archive();
    tar.load("../test/example/main.tar.gz");
    tar.list_files();
    tar.extract("aaa");
    tar.readfile("aaa");
    tar.set_target("./ffff/");
    tar.extract_all();

    // file test
    print("File test");
    readfile("/proc/cmdline");
    string curdir = pwd();
    cd("..");

    create_dir("uuu");
    remove_dir("uuu");
    cd(curdir);
    find(".");
    create_dir("uuu/aaa/fff");
    writefile("uuu/aaa/fff/ggg","ymp");
    remove_all("uuu");
    pwd();

    // logger test
    print("Logging test");
    error_add("Hello World");
    debug("debug test");

    // command test
    print("Command test");
    getoutput("echo -n hmmm");
    run_silent("non-command -non-parameter");
    run("false");

    // package test
    print("Package test");
    var pkg1 = new package();
    pkg1.load("../test/example/metadata-binary.yaml");
    join(", ",{"aaa","bbb"});

    // index test
    print("Repository test");
    get_repos();
    
    //array test
    print("Array test");
    var a = new array();
    a.add("aa");
    a.add("bb");
    a.add("cc");
    a.reverse();
    a.pop(0);
    a.remove("aa");
    a.has("bb");
    a.insert("dd",0);
    a.set({"yumusak","ge"});
    a.get();

    // Binary test
    print("Binary test");
    iself("ymp-test");
    is64bit("ymp");
    print(calculate_sha1sum("/bin/bash"));

    // ttysize test
    print("C functions test");
    tty_size_init();
    get_tty_width();
    get_tty_height();

    // which test
    which("bash");

    // users test
    get_uid_by_user("root");
    switch_user("root");

    // value test
    print("value test");
    get_value("interactive");
    error_add("Error test");
    error(0);

}
