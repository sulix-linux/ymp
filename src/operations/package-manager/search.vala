public int search_main(string[] args){
    if(get_bool("package")){
        return search_pkgrepo_main(args);
    }
    if(get_bool("source")){
        return search_srcrepo_main(args);
    }
    if(get_bool("file")){
        return search_files_main(args);
    }
    if(get_bool("installed")){
        return search_installed_main(args);
    }
    return 0;
}

public int search_installed_main(string[] args){
    foreach(string pkg in list_installed_packages()){
        var p = get_installed_package(pkg);
        foreach(string arg in args){
            if(arg in p.get("description") || arg in p.name){
                print((p.name+"\t"+p.get("description")).replace(arg,colorize(arg,red)));
            }
        }
    }
    return 0;
}


public int search_pkgrepo_main(string[] args){
    foreach(repository repo in get_repos()){
        foreach(string pkg in repo.list_packages()){
            var p = repo.get_package(pkg);
            foreach(string arg in args){
                if(arg in p.get("description") || arg in  p.name ){
                    print((p.name+"\t"+p.get("description")).replace(arg,colorize(arg,red)));
                }
            }
        }
    }
    return 0;
}

public int search_srcrepo_main(string[] args){
    foreach(repository repo in get_repos()){
        foreach(string pkg in repo.list_sources()){
            var p = repo.get_source(pkg);
            foreach(string arg in args){
                if(arg in p.get("description") || arg in  p.name ){
                    print((p.name+"\t"+p.get("description")).replace(arg,colorize(arg,red)));
                }
            }
        }
    }
    return 0;
}

public int search_files_main(string[] args){
    foreach(string pkg in list_installed_packages()){
        string files = readfile(get_storage()+"/files/"+pkg);
        foreach(string file in files.split("\n")){
            if(file.length < 41){
                continue;
            }
            foreach(string arg in args){
                if(Regex.match_simple(arg, "/"+file[41:])){
                    print(pkg+" => /"+file[41:]);
                }
            }
        }
    }
    return 0;
}

void search_init(){
    var h = new helpmsg();
    h.name = _("search");
    h.minargs=1;
    h.description = _("Search packages");
    h.add_parameter("--package", _("Search package in binary package repository."));
    h.add_parameter("--source", _("Search package in source package repository."));
    h.add_parameter("--installed", _("Search package in installed packages."));
    h.add_parameter("--file", _("Searches for packages by package file."));
    add_operation(search_main,{_("search"),"search","sr"},h);
}
