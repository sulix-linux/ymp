#if no_libarchive

public class archive {

    private string archive_path;

    private string target_path;
    public void set_target(string path){
        if(path != null){
            target_path = path;
        }
    }

    public void load(string path){
        archive_path = path;
    }
    public string[] list_files (){
        return getoutput("tar -f --list '"+archive_path+"'").split("\n");
    }
    public void extract_all(){
        if (target_path == null){
            target_path = "./";
        }
        run_silent("tar -xf -C '"+target_path+"' '"+archive_path+"'");
    }
    public void extract(string path){
        if (target_path == null){
            target_path = "./";
        }
        run_silent("tar -xf -C '"+target_path+"' '"+archive_path+"' '"+path+"'");
    }
}
#else

public class archive {

    Archive.Read archive;
    private string archive_path;
    private string target_path;

    public void load(string path){
        archive_path = path;
    }
    private void load_archive(string path){
        archive = new Archive.Read();
        archive.support_filter_all ();
        archive.support_format_all ();
        if (archive.open_filename (archive_path, 10240) != Archive.Result.OK) {
            log.error_add("Error: " + archive.error_string ());
            log.error(archive.errno ());
        }
    }
    public string[] list_files (){
        load_archive(archive_path);
        unowned Archive.Entry entry;
        string[] ret = {};
        while (archive.next_header (out entry) == Archive.Result.OK) {
            ret += entry.pathname ();
            archive.read_data_skip ();
        }
    return ret;
    }

    public void set_target(string path){
        if(path != null){
            target_path = path;
        }
    }

    public void extract (string path) {
        load_archive(archive_path);
        Archive.ExtractFlags flags;
        flags = Archive.ExtractFlags.TIME;
        flags |= Archive.ExtractFlags.PERM;
        flags |= Archive.ExtractFlags.ACL;
        flags |= Archive.ExtractFlags.FFLAGS;

        Archive.WriteDisk extractor = new Archive.WriteDisk ();
        extractor.set_options (flags);
        extractor.set_standard_lookup ();

        unowned Archive.Entry entry;
        Archive.Result last_result;
        while ((last_result = archive.next_header (out entry)) == Archive.Result.OK) {
            if (entry.pathname() != path){
                continue;
            }
            #if DEBUG
            log.debug("Extracting: "+path);
            #endif

            if (target_path == null){
                target_path = "./";
            }
            entry.set_pathname(target_path+"/"+path);

            if (extractor.write_header (entry) != Archive.Result.OK) {
                continue;
            }

            uint8[] buffer = null;
            Posix.off_t offset;
            while (archive.read_data_block (out buffer, out offset) == Archive.Result.OK) {
                if (extractor.write_data_block (buffer, offset) != Archive.Result.OK) {
                    break;
                }
            }
        }
    }

    public void extract_all(){
        foreach (string path in list_files()){
            extract(path);
        }
    }

}

#endif
