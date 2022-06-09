//DOC: ## class package
//DOC: inary package struct & functions
//DOC: Example usage:
//DOC: ```vala
//DOC: var pkg = new package();
//DOC: pkg.load_from_archive("/tmp/bash-5.0-x86_64.inary");
//DOC: stdout.printf(pkg.get("archive-hash"));
//DOC: foreach(string pkgname in pkg.dependencies){
//DOC:     stdout.printf(pkgname);
//DOC: }
//DOC: var pkg2 = new package();
//DOC: pkg2.load("/tmp/metadata.yaml");
//DOC: if(pkg2.is_installed()){
//DOC:     stdout.printf(pkg2+" installed");
//DOC: }
//DOC: ```
public class package {
    private yamlfile yaml;
    public string name;
    public string version;
    public string[] dependencies;
    public string[] provides;
    public string repo_address;
    private string pkgarea;
    private archive pkgfile;

    //DOC: `void package.load(string metadata):`
    //DOC: Read package information from metadata file
    public void load(string metadata){
        yaml = new yamlfile();
        yaml.load(metadata);
        pkgarea = yaml.get("inary.package");
        read_values();
    }

    //DOC: `void package.load_from_data(string data):`
    //DOC: Read package information from string data
    public void load_from_data(string data){
        yaml = new yamlfile();
        pkgarea = data;
        read_values();
    }

    //DOC: `void package.load_from_archive(string path):`
    //DOC: Read package information from inary file
    public void load_from_archive(string path){
        pkgfile = new archive();
        pkgfile.load(path);
        var metadata = pkgfile.readfile("metadata.yaml");
        yaml = new yamlfile();
        load_from_data(yaml.get_area(metadata,"inary.package"));
    }

    //DOC: `string[] package.list_files():`
    //DOC: return inary package files list
    public string[] list_files(){
        if(pkgfile == null){
            error_add("Package archive missing");
        }
        string files = pkgfile.readfile("files");
        return ssplit(files,"\n");
    }

    private void read_values(){
        name = get("name");
        version = get("version");
        dependencies = gets("dependencies");
        provides = gets("provides");
    }

    //DOC: `string[] package.gets(string name):`
    //DOC: Get package array value
    public string[] gets(string name){
        if (yaml.has_area(pkgarea,name)){
            return yaml.get_array(pkgarea,name);
        }
        return {};
    }

    //DOC: `string package.get(string name):`
    //DOC: Get package value
    public string get(string name){
        if (yaml.has_area(pkgarea,name)){
            debug(@"Package data: $name");
            return yaml.get_value(pkgarea,name);
        }
        warning(@"Package information broken: $name");
        return "";
    }

    public string get_uri(){
        if(repo_address == null){
            return "";
        }
        return repo_address + "/" + get("uri");
    }

    //DOC: `void package.extract():`
    //DOC: extract package to quarantine directory
    //DOC: quarantine directory is **get_storage()+"/quarantine"**;
    //DOC: Example inary archive format:
    //DOC: ```yaml
    //DOC: package.inary
    //DOC:   ├── data.tar.gz
    //DOC:   │     ├ /usr
    //DOC:   │     │  └ ...
    //DOC:   │     └ /etc
    //DOC:   │        └ ...
    //DOC:   ├── files
    //DOC:   └── metadata.yaml
    //DOC: ```
    //DOC: * **metadata.yaml** file is package information data.
    //DOC: * **files** is file list
    //DOC: * **data.tar.gz** in package archive
    public void extract(){
        if(pkgfile == null){
            error_add("Package archive missing");
            return;
        }
        var rootfs_medatata = get_storage()+"/quarantine/rootfs"+STORAGEDIR+"/metadata/";
        var rootfs_files = get_storage()+"/quarantine/rootfs"+STORAGEDIR+"/files/";
        if(isfile(rootfs_medatata+name+".yaml")){
            debug("skip quartine package extract:"+name);
            return;
        }
        // extract data archive
        pkgfile.set_target(get_storage()+"/quarantine");
        foreach (string data in pkgfile.list_files()){
            // Allowed formats: data.tar.xz data.zip data.tar.zst data.tar.gz ..
            if(startswith(data,"data.")){
                // 1. data.* file extract to quarantine from inary package
                pkgfile.extract(data);
                var datafile = get_storage()+"/quarantine/"+data;
                // 2. data.* package extract to quarantine/rootfs
                var file_archive = new archive();
                file_archive.load(datafile);
                file_archive.set_target(get_storage()+"/quarantine/rootfs");
                file_archive.extract_all();
                // 3. remove data.* file
                remove_file(datafile);
                break;
            }
        }
        // extract metadata
        pkgfile.set_target(rootfs_medatata);
        pkgfile.extract("metadata.yaml");
        move_file(rootfs_medatata+"metadata.yaml",rootfs_medatata+name+".yaml");
        // extract files
        pkgfile.set_target(rootfs_files);
        pkgfile.extract("files");
        move_file(rootfs_medatata+"files",rootfs_files+name);
        error(3);
    }

    //DOC: `bool package.is_installed():`
    //DOC: return true if package is installed
    public bool is_installed(){
        return is_installed_package(name);
    }
}

//DOC: ## Miscellaneous package functions
//DOC: package functions outside package class

//DOC: `string[] list_installed_packages():`
//DOC: return installed package names array
public string[] list_installed_packages(){
    string[] pkgs = {};
    foreach(string fname in listdir(get_storage()+"/metadata")){
        pkgs += ssplit(fname,".")[0];
    }
    return pkgs;
}
//DOC: `package get_installed_packege(string name):`
//DOC: get package object from installed package name
public package get_installed_packege(string name){
    package pkg = new package();
    string metadata = get_metadata_path(name);
    debug("Loading package metadata from: "+metadata);
    pkg.load(metadata);
    return pkg;
}

//DOC: `bool is_installed_package():`
//DOC: return true if package installed
public bool is_installed_package(string name){
    return isfile(get_metadata_path(name));
}

