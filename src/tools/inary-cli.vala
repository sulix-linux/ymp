int main (string[] args) {
    Inary inary = inary_init(args);
    string[] new_args = argument_process(args);
    if(new_args.length < 2){
        help_main(args);
    }
    inary.add_process(new_args[1],new_args[2:]);
    inary.run();
    error(1);
    return 0;
}