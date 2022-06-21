//DOC: ## Dependency analysis
//DOC: resolve dependencies
private string[] need_install;
private string[] cache_list;

private void resolve_process(string[] names){
    foreach(string name in names){
        // 1. block process packages for multiple times.
        if(name in cache_list){
            return;
        }else{
            cache_list += name;
        }
        // 2. process if not installed or need install
        if (!(name in need_install)){
            // get package object
            package pkg = null;
            if(isfile(name)){
                pkg = get_package_from_file(name);
            }else{
                pkg = get_package_from_repository(name);
            }
            if(pkg == null){
                return;
            }
            if(is_installed_package(name)){
                if(pkg.release <= get_installed_package(name).release){
                    return;
                }
            }
            // run recursive function
            resolve_process(pkg.dependencies);
            // add package to list
            debug(name);
            need_install += name;
        }
    }
    return;
}
//DOC: `string[] resolve_dependencies(string[] names):`
//DOC: return package name list with required dependencies
public string[] resolve_dependencies(string[] names){
    if(get_bool("ignore-dependency")){
        return names;
    }
    // reset need list
    need_install = {};
    // reset cache list
    cache_list = {};
    // process
    resolve_process(names);
    error(3);
    return need_install;
}
