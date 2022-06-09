int main(string[] args){
    inary_init(args);
    if(args.length < 2){
        error_add("Archive Missing");
        error(2);
    }
    var tar = new archive();
    string[] new_args = argument_process(args);
    tar.load(new_args[1]);
    if(get_bool("list")){
        foreach(string file in tar.list_files()){
            print(file);
        }
        return 0;
    }
    if(new_args.length > 2){
        foreach(string file in new_args[2:]){
            tar.extract(file);
        }
        return 0;
    }
    tar.extract_all();
    return 0;
}
