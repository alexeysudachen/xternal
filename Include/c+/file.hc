
/*

	Copyright (c) 2010-2016, Alexey Sudachen, https://goo.gl/RlZcQR
	See license rules in C+.hc

*/

#ifndef C_once_E9479D04_5D69_4A1A_944F_0C99A852DC0B
#define C_once_E9479D04_5D69_4A1A_944F_0C99A852DC0B

#ifdef _BUILTIN
#	define _C_FILE_BUILTIN
#endif

#if defined __MINGW32__ && __GNUC__ < 4 || defined __CYGWIN__
#	undef _FILEi32
#	define _FILEi32
#endif

//#if !defined _FILEi32 && !defined __windoze
//#	define  _LARGEFILE64_SOURCE
//#endif

#include "C+.hc"
#include "string.hc"
#include "buffer.hc"

#include "crypto/random.hc"

#ifndef __windoze
#	include <dirent.h>
#	include <sys/file.h>
#endif

#ifdef _FILEi32
typedef long file_offset_t;
#else
typedef quad_t file_offset_t;
#endif

enum { C_FILE_COPY_BUFFER_SIZE = 4096, };

#ifdef _C_FILE_BUILTIN
# define _C_FILE_BUILTIN_CODE(Code) Code
# define _C_FILE_EXTERN
#else
# define _C_FILE_BUILTIN_CODE(Code)
# define _C_FILE_EXTERN extern
#endif

enum
{
    Oj_FILE_GROUP   = 100,
    Oj_Close_OjMID,
    Oj_Read_OjMID,
    Oj_Write_OjMID,
    Oj_Available_OjMID,
    Oj_Eof_OjMID,
    Oj_Length_OjMID,
    Oj_Seek_OjMID,
    Oj_Tell_OjMID,
    Oj_Flush_OjMID,
    Oj_Read_Line_OjMID,
    Oj_Truncate_OjMID,
    Oj_Write_Line_OjMID,
    Oj_Read_All_OjMID,
    Oj_Rewind_OjMID,
    Oj_FILE_GROUP_END
};

#ifdef __windoze
enum { C_PATH_SEPARATOR = '\\' };
#else
enum { C_PATH_SEPARATOR = '/' };
#endif

void File_Check_Error(char *op, FILE *f, char *fname, int look_to_errno)
#ifdef _C_FILE_BUILTIN
{
	int err = 0;
	char *errS = 0;

	if ( look_to_errno )
	{
		if ( (err = errno) ) 
			errS = strerror(err);
	}
	else if ( f && !feof(f) && ( err = ferror(f) ) )
	{
		errS = strerror(err);
		clearerr(f);
	}

	if (err)
		__Raise_Format(C_ERROR_IO,("%s failed on file '%s': %s",op,fname,errS));
}
#endif
;

#define Raise_If_File_Error(Op,Fname) File_Check_Error(Op,0,Fname,1)

char *Path_Basename(char *path)
#ifdef _C_FILE_BUILTIN
{
	char *ret = 0;
	if ( path )
	{
		char *p = strrchr(path,'/');
#ifdef __windoze
		char *p2 = strrchr(path,'\\');
		if ( !p || p < p2 ) p = p2;
#endif
		if (p)
			ret = Str_Copy(p + 1);
		else
			ret = Str_Copy(path);
	}
	return ret;
}
#endif
;

char *Path_Dirname(char *path)
#ifdef _C_FILE_BUILTIN
{
	char *ret = 0;
	if ( path )
	{
		char *p = strrchr(path,'/');
#ifdef __windoze
		char *p2 = strrchr(path,'\\');
		if ( !p || p < p2 ) p = p2;
#endif
		if ( p )
		{
			if ( p-path > 0 )
				ret = Str_Copy_L(path,p-path);
			else
#ifdef __windoze
				ret = Str_Copy_L("\\",1);
#else
				ret = Str_Copy_L("/",1);
#endif
		}
	}
	return ret;
}
#endif
;

char *Temp_Directory()
#ifdef _C_FILE_BUILTIN
{
	enum { tmp_len = 512 };
	char *ptr = 0;
	__Auto_Ptr(ptr)
	{
#ifdef __windoze
		wchar_t *tmp = __Malloc((tmp_len+1)*sizeof(wchar_t));
		GetTempPathW(tmp_len+1,tmp);
		ptr = Str_Unicode_To_Utf8(tmp);
#else
		char *tmp = getenv("TEMP");
		if ( !tmp ) tmp = "/tmp";
		ptr = Str_Copy(tmp);
#endif
	}
	return ptr;
}
#endif
;

char *Current_Directory()
#ifdef _C_FILE_BUILTIN
{
	enum { tmp_len = 512 };
	char *ptr = 0;
	__Auto_Ptr(ptr)
	{
#ifdef __windoze
		wchar_t *tmp = __Malloc((tmp_len+1)*sizeof(wchar_t));
		ptr = Str_Unicode_To_Utf8(_wgetcwd(tmp,tmp_len));
#else
		char *tmp = __Malloc(tmp_len+1);
		ptr = Str_Copy(getcwd(tmp,tmp_len));
#endif
	}
	return ptr;
}
#endif
;

void Change_Directory(char *dirname)
#ifdef _C_FILE_BUILTIN
{
	__Auto_Release
	{
		int err;
#ifdef __windoze
		wchar_t *tmp = Str_Utf8_To_Unicode(dirname);
		err = _wchdir(tmp);
#else
		err = chdir(dirname);
#endif
		if ( err == - 1 )
			Raise_If_File_Error("chdir",dirname);
	}
}
#endif
;

char *Path_Normilize_Npl_(char *path, int sep)
#ifdef _C_FILE_BUILTIN
{
	int i = 0, ln = strlen(path);
	char *S = __Malloc_Npl(ln+1);
	*S = 0;

	while ( *path )
	{
		if ( *path != '/' && *path != '\\' )
			S[i++] = *path;
		else
			if ( !i || S[i-1] != sep ) 
				S[i++] = sep;
		++path;
	}

	S[i] = 0;
	if ( i && S[i-1] == sep ) S[--i] = 0;

	return S;
}
#endif
;

#define Path_Normilize_Npl(S) Path_Normilize_Npl_(S,C_PATH_SEPARATOR)
#define Path_Normilize(S) __Pool(Path_Normilize_Npl(S))
#define Path_Normposix_Npl(S) Path_Normilize_Npl_(S,'/')
#define Path_Normposix(S) __Pool(Path_Normilize_Npl(S))

char *Path_Unique_Name(char *dirname,char *pfx, char *sfx)
#ifdef _C_FILE_BUILTIN
{
#ifdef __windoze
	char DELIMITER[] = "\\";
#else
	char DELIMITER[] = "/";
#endif
	char unique[2+4+6] = {0};
	char out[(sizeof(unique)*8+5)/6+1] = {0};
	int pid = getpid();
	uint_t tmx = (uint_t)time(0);
	Unsigned_To_Two(pid,unique);
	Unsigned_To_Four(tmx,unique+2);
	System_Random(unique+6,sizeof(unique)-6);
	Str_Xbit_Encode(unique,sizeof(unique)*8,6,Str_6bit_Encoding_Table,out);
	if ( dirname )
		return Str_Join_5(0,dirname,DELIMITER,(pfx?pfx:""),out,(sfx?sfx:""));
	else
		return Str_Join_3(0,(pfx?pfx:""),out,(sfx?sfx:""));
}
#endif
;

char *Path_Join(char *dir, char *name)
#ifdef _C_FILE_BUILTIN
{
#ifdef __windoze
	enum { DELIMITER = '\\' };
#else
	enum { DELIMITER = '/' };
#endif
	if ( dir && *dir )
	{
		int L = strlen(dir);
		while ( *name == DELIMITER ) ++name;
		if ( dir[L-1] == DELIMITER )
			return Str_Concat(dir,name);
		else
			return Str_Join_2(DELIMITER,dir,name);
	}
	else
		return Str_Copy(name);
}
#endif
;

char *Path_Suffix(char *path)
#ifdef _C_FILE_BUILTIN
{
	char *ret = 0;
	char *p = strrchr(path,'.');
	if ( p )
	{
		char *p1 = strrchr(path,'/');
		if ( p1 && p1 > p ) p = p1;
#ifdef __windoze
		__Gogo 
		{
			char *p2 = strrchr(path,'\\');
			if ( p2 && p2 > p ) p = p2;
		}
#endif
	}
	if ( p && *p == '.' )
		ret = Str_Copy(p);
	return ret;
}
#endif
;

char *Path_Unsuffix(char *path)
#ifdef _C_FILE_BUILTIN
{
	char *ret = 0;
	char *p = strrchr(path,'.');
	if ( p )
	{
		char *p1 = strrchr(path,'/');
		if ( p1 && p1 > p ) p = p1;
#ifdef __windoze
		__Gogo 
		{
			char *p2 = strrchr(path,'\\');
			if ( p2 && p2 > p ) p = p2;
		}
#endif
	}
	if ( p && *p == '.' )
		ret = Str_Copy_L(path,p-path);
	return ret;
}
#endif
;

char *Path_Fullname(char *path)
#ifdef _C_FILE_BUILTIN
{
#ifdef __windoze
	if ( path )
	{
		wchar_t *foo;
		char *ret = 0;
		__Auto_Ptr(ret)
		{
			wchar_t *tmp = __Malloc((MAX_PATH+1)*sizeof(wchar_t));
			*tmp = 0;
			GetFullPathNameW(Str_Utf8_To_Unicode(path),MAX_PATH,tmp,&foo);
			ret = Str_Unicode_To_Utf8(tmp);
		}
		return ret;
	}
#else
	if ( path && *path != '/' )
	{
		char *ret = 0;
		__Auto_Ptr(ret) ret = Path_Join(Current_Directory(),path);
		return ret;
	}
#endif
	return Str_Copy(path);
}
#endif
;

typedef struct _C_FILE_STATS
{
	time_t ctime;
	time_t mtime;
	quad_t length;

	struct {
		int exists: 1;
		int is_regular: 1;
		int is_tty: 1;
		int is_symlink: 1;
		int is_unisok: 1;
		int is_directory: 1;
		int is_writable: 1;
		int is_readable: 1;
		int is_executable: 1;
	} f;

} C_FILE_STATS;

#ifdef __windoze
#if !defined _FILEi32  
typedef struct _stat64 _C_stat;
#else
typedef struct _stat _C_stat;
#endif

#if !defined S_IWUSR 
enum 
{ 
	S_IWUSR = _S_IWRITE,
	S_IRUSR = _S_IREAD,
	S_IXUSR = _S_IEXEC,
};
#endif  
#else
typedef struct stat _C_stat;
#endif        

C_FILE_STATS *File_Translate_Filestats(_C_stat *fst,C_FILE_STATS *st,int exists)
#ifdef _C_FILE_BUILTIN
{
	if ( !st ) st = __Malloc(sizeof(C_FILE_STATS));
	memset(st,0,sizeof(*st));
	st->f.exists       = exists;
	st->f.is_regular   = !!((fst->st_mode&S_IFMT) & S_IFREG);
	st->f.is_directory = !!((fst->st_mode&S_IFMT) & S_IFDIR);
#ifndef __windoze  
	st->f.is_symlink   = !!((fst->st_mode&S_IFMT) & S_IFLNK);    
	st->f.is_unisok    = !!((fst->st_mode&S_IFMT) & S_IFSOCK);
#endif  
	st->f.is_writable  = (fst->st_mode&S_IWUSR) != 0;
	st->f.is_readable  = (fst->st_mode&S_IRUSR) != 0;
	st->f.is_executable = (fst->st_mode&S_IXUSR) != 0;
	st->length = fst->st_size;
	st->ctime  = fst->st_ctime;
	st->mtime  = fst->st_mtime;

	return st;
}
#endif
;

C_FILE_STATS *File_Get_Stats(char *name,C_FILE_STATS *st,int ignorerr)
#ifdef _C_FILE_BUILTIN
{
	_C_stat fst = {0};
	int err;
#ifdef __windoze
	wchar_t *uni_name = Str_Utf8_To_Unicode(name);
#ifndef _FILEi32  
	err = _wstat64(uni_name,&fst);
#else
	err = _wstat(uni_name,&fst);
#endif
	__Release(uni_name);
#else
	err = stat(name,&fst);
#endif
	if ( !err || ignorerr )
	{
		st = File_Translate_Filestats(&fst,st,!err);
	}
	else if ( err && !ignorerr )              
	{
		int eno = errno;
		if ( st ) memset(st,0,sizeof(*st));
		if ( eno == ENOENT || eno == ENOTDIR )
			__Raise_Format(C_ERROR_DOESNT_EXIST,("file '%s' does not exist",name));
		File_Check_Error("getting stats",0,name,1); 
	}
	return st;
}
#endif
;

C_FILE_STATS *File_Get_Stats_Reuse(char *name, C_FILE_STATS **stp)
#ifdef _C_FILE_BUILTIN
{
	if ( stp && *stp ) 
		return *stp;
	else
	{
		C_FILE_STATS *st = File_Get_Stats(name,0,0);
		if ( stp ) *stp = st;
		return st;
	}
}
#endif
;

time_t File_Ctime(char *name) 
	_C_FILE_BUILTIN_CODE({C_FILE_STATS st={0}; return File_Get_Stats(name,&st,0)->ctime;});
time_t File_Mtime(char *name)
	_C_FILE_BUILTIN_CODE({C_FILE_STATS st={0}; return File_Get_Stats(name,&st,0)->mtime;});
quad_t File_Length(char *name)
	_C_FILE_BUILTIN_CODE({C_FILE_STATS st={0}; return File_Get_Stats(name,&st,0)->length;});
int File_Exists(char *name)
	_C_FILE_BUILTIN_CODE({C_FILE_STATS st={0}; return File_Get_Stats(name,&st,1)->f.exists;});
int File_Is_Regular(char *name)
	_C_FILE_BUILTIN_CODE({C_FILE_STATS st={0}; return File_Get_Stats(name,&st,0)->f.is_regular;});
int File_Is_Directory(char *name)
	_C_FILE_BUILTIN_CODE({C_FILE_STATS st={0}; return File_Get_Stats(name,&st,0)->f.is_directory;});
int File_Is_Writable(char *name)
	_C_FILE_BUILTIN_CODE({C_FILE_STATS st={0}; return File_Get_Stats(name,&st,0)->f.is_writable;});
int File_Is_Readable(char *name)
	_C_FILE_BUILTIN_CODE({C_FILE_STATS st={0}; return File_Get_Stats(name,&st,0)->f.is_readable;});
int File_Is_Executable(char *name)
	_C_FILE_BUILTIN_CODE({C_FILE_STATS st={0}; return File_Get_Stats(name,&st,0)->f.is_executable;});

void Delete_Directory(char *name)
#ifdef _C_FILE_BUILTIN
{
	C_FILE_STATS st;
	if ( File_Get_Stats(name,&st,1)->f.is_directory )
	{
#ifdef __windoze
		if ( _wrmdir(Str_Utf8_To_Unicode(name)) < 0 )
#else
		if ( rmdir(name) < 0 )
#endif  
			File_Check_Error("rmdir",0,name,1);
	}
}
#endif
;

void Create_Directory(char *name)
#ifdef _C_FILE_BUILTIN
{
	C_FILE_STATS st;
	if ( !File_Get_Stats(name,&st,1)->f.is_directory )
	{
#ifdef __windoze
		if ( _wmkdir(Str_Utf8_To_Unicode(name)) < 0 )
#else
		if ( mkdir(name,0755) < 0 )
#endif  
			File_Check_Error("mkdir",0,name,1);
	}
}
#endif
;

void Create_Directory_In_Depth(char *name)
#ifdef _C_FILE_BUILTIN
{
	int nL = name ? strlen(name) : 0;
	if ( nL 
		&& !(nL == 2 && name[1] == ':')  
		&& !(nL == 1 && (name[0] == '/' || name[0] == '\\') ))
	{
		Create_Directory_In_Depth(Path_Dirname(name));
		Create_Directory(name);
	}
}
#endif
;

void Create_Required_Dirs(char *name)
#ifdef _C_FILE_BUILTIN
{
	__Auto_Release
	{
		char *dirpath = Path_Dirname(name);
		Create_Directory_In_Depth(dirpath);
	}
}
#endif
;

enum _C_DIRLIST_FLAGS
{
	FILE_LIST_ALL = 0,
	FILE_LIST_DIRECTORIES = 1,
	FILE_LIST_FILES = 2,
};

C_ARRAY *File_List_Directory(char *dirname, unsigned flags)
#ifdef _C_FILE_BUILTIN
{
#ifdef __windoze
	WIN32_FIND_DATAW fdtw;
	HANDLE hfnd;
#else
	DIR *dir;
#endif
	void *L = Array_Pchars();

	__Auto_Release
	{
		if (!flags) flags = FILE_LIST_DIRECTORIES|FILE_LIST_FILES;

#ifdef __windoze
		hfnd = FindFirstFileW(Str_Utf8_To_Unicode(Path_Join(dirname,"*.*")),&fdtw);
		if ( hfnd && hfnd != INVALID_HANDLE_VALUE )
		{
			do
			if ( wcscmp(fdtw.cFileName,L".") && wcscmp(fdtw.cFileName,L"..") )
			{
				int m = fdtw.dwFileAttributes&FILE_ATTRIBUTE_DIRECTORY ?
FILE_LIST_DIRECTORIES : FILE_LIST_FILES;
				if ( m & flags )
				{
					char *name = Str_Unicode_To_Utf8_Npl(fdtw.cFileName);
					Array_Push(L,name);
				}
			}
			while( FindNextFileW(hfnd,&fdtw) );
			FindClose(hfnd);
		}
#else
		dir = __Pool_Ptr(opendir(dirname),closedir);
		if ( dir )
		{
			struct dirent *dp = 0;
			while ( 0 != (dp = readdir(dir)) )
				if ( strcmp(dp->d_name,".") && strcmp(dp->d_name,"..") )
				{
					int m;
#ifdef __QNX__
					struct dirent_extra *extra;
					for(extra = _DEXTRA_FIRST(dp)
						;_DEXTRA_VALID(extra, dp) 
						;extra = _DEXTRA_NEXT(extra)) 
					{
						switch(extra->d_type)
                        case _DTYPE_STAT:
						{
							struct dirent_extra_stat *dst = (void*)extra;
							m = ( dst->d_stat.st_mode & S_IFDIR )                  
								? FILE_LIST_DIRECTORIES 
								: FILE_LIST_FILES;
						}
					}
#else
					m = dp->d_type == DT_DIR ?
FILE_LIST_DIRECTORIES : FILE_LIST_FILES;
#endif
					if ( m & flags )
						Array_Push(L,Str_Copy_Npl(dp->d_name,-1));
				}
		}
#endif
	}

	return L;
}
#endif
;

#ifdef __windoze
#define utf8_unlink(S) _wunlink(Str_Utf8_To_Unicode(S));
#else
#define utf8_unlink(S) unlink(S)
#endif

void File_Unlink(char *name, int force)
#ifdef _C_FILE_BUILTIN
{
	C_FILE_STATS st;
	int i, err = 0;

	__Auto_Release
	{
		File_Get_Stats(name,&st,0);

		if ( st.f.exists )
		{
			if ( st.f.is_directory && force )
			{
				C_ARRAY *L = File_List_Directory(name,0);
				for ( i = 0; i < L->count; ++i )
					File_Unlink(Path_Join(name,L->at[i]),force);
				Delete_Directory(name);
			}
			else
				err = utf8_unlink(name);
		}

		if ( err < 0 )
			File_Check_Error("unlink",0,name,1); 
	}
}
#endif
;

void File_Rename(char *old_name, char *new_name)
#ifdef _C_FILE_BUILTIN
{
	int err = 0;
#ifdef __windoze
	wchar_t *So = Str_Utf8_To_Unicode(old_name);
	wchar_t *Sn = Str_Utf8_To_Unicode(new_name);
	err = _wrename(So,Sn);
	__Release(Sn);
	__Release(So);
#else
	err = rename(old_name,new_name);
#endif
	if ( err < 0 )
		File_Check_Error("rename",0,old_name,1); 
}
#endif
;

typedef struct _C_FILE
{
	FILE *fd;
	char *name;
	int shared;
} C_FILE;

int Raise_If_Cfile_Is_Not_Opened(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	if ( !f || !f->fd )
		__Raise_Format(C_ERROR_IO,("file '%s' is already closed",(f?f->name:"")));
	return 1;
}
#endif
;

int Oj_Close(void *f) _C_FILE_BUILTIN_CODE(
{ 
	return ((int(*)(void*))C_Find_Method_Of(&f,Oj_Close_OjMID,C_RAISE_ERROR))
		(f); 
});

int Cfile_Close(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	if ( f->fd )
	{
		fclose(f->fd);
		f->fd = 0;
	}
	return 0;
}
#endif
;

int Pfile_Close(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	int ret = 0;
	if ( f->fd )
	{
#ifdef __windoze
		ret = _pclose(f->fd);
#else
		ret = pclose(f->fd);
#endif
		f->fd = 0;
	}
	return ret;
}
#endif
;

void Oj_Flush(void *f) _C_FILE_BUILTIN_CODE(
{ 
	((void(*)(void*))C_Find_Method_Of(&f,Oj_Flush_OjMID,C_RAISE_ERROR))
		(f); 
});

void Cfile_Flush(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	if ( f->fd )
		if ( fflush(f->fd) )
		{
			File_Check_Error("flush",0,f->name,1); 
		}
}
#endif
;

void Cfile_Destruct(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	Cfile_Close(f);
	free(f->name);
	__Destruct(f);
}
#endif
;

void Pfile_Destruct(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	Pfile_Close(f);
	free(f->name);
	__Destruct(f);
}
#endif
;

C_FILE_STATS *Cfile_Stats(C_FILE *f,C_FILE_STATS *st)
#ifdef _C_FILE_BUILTIN
{
	if ( Raise_If_Cfile_Is_Not_Opened(f) )
	{
		_C_stat fst = {0};
		int err;

#ifdef __windoze
#if !defined _FILEi32  
		err = _fstat64(fileno(f->fd),&fst);
#else
		err = _fstat(fileno(f->fd),&fst);
#endif
#else
		err = fstat(fileno(f->fd),&fst);
#endif        
		if ( err )
			File_Check_Error("getting stats",f->fd,f->name,0); 
		return File_Translate_Filestats(&fst,st,!err);
	}
	return 0;
};
#endif
;

int Oj_Eof(void *f) _C_FILE_BUILTIN_CODE(
{ 
	return 
		((int(*)(void*))C_Find_Method_Of(&f,Oj_Eof_OjMID,C_RAISE_ERROR))
			(f); 
});

int Cfile_Eof(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	if ( f->fd )
	{
		return feof(f->fd);
	}
	return 1;
}
#endif
;

#define Oj_Read_Full(File,Buf,Count) Oj_Read(File,Buf,Count,-1)

int Oj_Read(void *f,void *buf,int count,int min_count) _C_FILE_BUILTIN_CODE(
{ 
	return 
		((int(*)(void*,void*,int,int))C_Find_Method_Of(&f,Oj_Read_OjMID,C_RAISE_ERROR))
			(f,buf,count,min_count); 
});

int Cfile_Read(C_FILE *f, void *buf, int count, int min_count)
#ifdef _C_FILE_BUILTIN
{
	if ( Raise_If_Cfile_Is_Not_Opened(f) )
	{
		int cc = 0;
		byte_t *d = (byte_t *)buf;
		if ( min_count < 0 ) min_count = count; 
		for ( ; cc < count ; )
		{
			int q = fread(d,1,count-cc,f->fd);
			if ( q <= 0 )
			{
				if ( feof(f->fd) )
				{
					if ( cc >= min_count ) 
						break;
					else 
						__Raise_Format(C_ERROR_IO,("end of file '%s'",f->name));
				}
				else 
					File_Check_Error("read",f->fd,f->name,0);
			}
			if ( !q && cc >= min_count) break;
			cc += q;
			d += q;
		}
		return cc;
	}
	return 0;
}
#endif
;

char *Oj_Read_Line(void *f) _C_FILE_BUILTIN_CODE(
{ 
	return 
		((void *(*)(void*))C_Find_Method_Of(&f,Oj_Read_Line_OjMID,C_RAISE_ERROR))
			(f); 
});

char *Cfile_Read_Line(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	if ( Raise_If_Cfile_Is_Not_Opened(f) )
	{
		int S_len = 0;
		char *S = 0;
		for(;;)
		{
			char S_local[512];
			char *q = fgets(S_local,sizeof(S_local),f->fd);
			if ( !q )
			{
				if ( feof(f->fd) )
					break;
				else
					File_Check_Error("readline",f->fd,f->name,0);
			}
			else
			{
				int q_len = strlen(q);
				S = __Realloc(S,S_len+q_len+1);
				memcpy(S+S_len,q,q_len);
				S_len += q_len;
				if ( S[S_len-1] == '\n' ) 
				{
					S[S_len-1] = 0; 
					break;
				}
				else S[S_len] = 0;
			}
		}
		return S;
	}
	return 0;
}
#endif
;

#define Oj_Write_Full(File,Buf,Count) Oj_Write(File,Buf,Count,-1)

int Oj_Write(void *f,void *buf,int count,int min_count) _C_FILE_BUILTIN_CODE(
{ 
	return 
		((int(*)(void*,void*,int,int))C_Find_Method_Of(&f,Oj_Write_OjMID,C_RAISE_ERROR))
			(f,buf,count,min_count); 
});

int Cfile_Write(C_FILE *f, void *buf, int count, int min_count)
#ifdef _C_FILE_BUILTIN
{
	if ( Raise_If_Cfile_Is_Not_Opened(f) )
	{
		int cc = 0;
		char *d = buf;
		for ( ; cc < count ; )
		{
			int q = fwrite(d,1,count-cc,f->fd);
			if ( q <= 0 )
				File_Check_Error("write",f->fd,f->name,0);
			if ( !q && cc >= min_count) 
				return cc;
			cc += q;
			d += q;
		}
		return cc;
	}
	return 0;
}
#endif
;

void Oj_Write_Line(void *f,char *text) _C_FILE_BUILTIN_CODE(
{ 
	((void(*)(void*,void*))C_Find_Method_Of(&f,Oj_Write_Line_OjMID,C_RAISE_ERROR))
		(f,text); 
});

void Cfile_Write_Line(C_FILE *f, char *text)
#ifdef _C_FILE_BUILTIN
{
	if ( Raise_If_Cfile_Is_Not_Opened(f) )
	{
		int Ln = text?strlen(text):0;
		if ( Ln )
			Cfile_Write(f,text,Ln,Ln);
		Cfile_Write(f,"\n",1,1);
		Cfile_Flush(f);
	}
}
#endif
;

quad_t Oj_Tell(void *f) _C_FILE_BUILTIN_CODE(
{ 
	return 
		((quad_t(*)(void*))C_Find_Method_Of(&f,Oj_Tell_OjMID,C_RAISE_ERROR))
			(f); 
});

quad_t Cfile_Tell(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	if ( Raise_If_Cfile_Is_Not_Opened(f) )
	{
		quad_t q = 
#ifdef __windoze 
#if !defined _FILEi32  
			_ftelli64(f->fd);
#else
			ftell(f->fd);
#endif
#else
			ftello(f->fd);
#endif
		if ( q < 0 )
			File_Check_Error("tell",f->fd,f->name,0);
		return q;
	}
	return 0;
}
#endif
;

quad_t Oj_Length(void *f) _C_FILE_BUILTIN_CODE(
{ return 
((quad_t(*)(void*))C_Find_Method_Of(&f,Oj_Length_OjMID,C_RAISE_ERROR))
(f); });

quad_t Cfile_Length(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	if ( Raise_If_Cfile_Is_Not_Opened(f) )
	{
		C_FILE_STATS st = {0};
		return Cfile_Stats(f,&st)->length; 
	}
	return 0;
}
#endif
;

quad_t Oj_Available(void *f) _C_FILE_BUILTIN_CODE(
{ 
	return 
		((quad_t(*)(void*))C_Find_Method_Of(&f,Oj_Available_OjMID,C_RAISE_ERROR))
			(f); 
});

quad_t Cfile_Available(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	if ( Raise_If_Cfile_Is_Not_Opened(f) )
	{
		C_FILE_STATS st;
		return Cfile_Stats(f,&st)->length - Cfile_Tell(f); 
	}
	return 0;
}
#endif
;

C_BUFFER *Oj_Read_All(void *f)
#ifdef _C_FILE_BUILTIN
{
	void *(*readall)(void*) = C_Find_Method_Of(&f,Oj_Read_All_OjMID,0);
	if ( readall )
		return readall(f);
	else
	{
		quad_t (*available)(void*) = C_Find_Method_Of(&f,Oj_Available_OjMID,0);
		int (*read)(void*,void*,int,int) = C_Find_Method_Of(&f,Oj_Read_OjMID,C_RAISE_ERROR);
		void *L;
		if ( available )
		{
			quad_t len = available(f);
			if ( len > INT_MAX )
				__Raise(C_ERROR_IO,"file to big to be read in one pass");
			L = Buffer_Init((int)len);
			if ( len )
				read(f,Buffer_Begin(L),(int)len,(int)len);
		}
		else
		{
			int (*eof)(void*) = C_Find_Method_Of(&f,Oj_Eof_OjMID,C_RAISE_ERROR);
			L = Buffer_Init(0);
			while ( !eof(f) )
			{
				byte_t local[1024];
				int q  = read(f,local,sizeof(local),0);
				if ( q > 0 ) Buffer_Append(L,local,q);
			}
		}
		return L;
	}
}
#endif
;

C_BUFFER *Cfile_Read_All(C_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	if ( Raise_If_Cfile_Is_Not_Opened(f) )
	{
		C_BUFFER *L;
		quad_t len = Cfile_Available(f);
		if ( len > INT_MAX )
			__Raise(C_ERROR_IO,"file to big to be read in one pass");
		L = Buffer_Reserve(0,(int)len);
		while ( len ) 
			/* windoze text mode reads less then available, so we need to read carefully*/
		{
			Buffer_Grow_Reserve(L,L->count+(int)len);
			L->count += Cfile_Read(f,L->at+L->count,(int)len,0);
			L->at[L->count] = 0;
			len = Cfile_Available(f);
		}
		return L;
	}
	return 0;
}
#endif
;

quad_t Oj_Seek(void *f, quad_t pos, int whence) _C_FILE_BUILTIN_CODE(
{ return 
((quad_t (*)(void*,quad_t,int))C_Find_Method_Of(&f,Oj_Seek_OjMID,C_RAISE_ERROR))
(f,pos,whence); });

void Oj_Rewind(void *f) _C_FILE_BUILTIN_CODE(
{ 
	quad_t (*f_seek)(void*,quad_t,int) = C_Find_Method_Of(&f,Oj_Seek_OjMID,0);
	if ( f_seek ) 
		f_seek(f,0,0);
	else
		((void(*)(void*))C_Find_Method_Of(&f,Oj_Rewind_OjMID,C_RAISE_ERROR))
			(f); 
});

quad_t Cfile_Seek(C_FILE *f, quad_t pos, int whence)
#ifdef _C_FILE_BUILTIN
{
	quad_t old = Cfile_Tell(f);
	if ( old < 0 ) return -1;

	if ( Raise_If_Cfile_Is_Not_Opened(f) )
	{
		int q = 
#ifdef __windoze 
#if !defined _FILEi32  
			_fseeki64(f->fd,pos,whence);
#else
			fseek(f->fd,(long)pos,whence);
#endif
#else
			fseeko(f->fd,pos,whence);
#endif
		if ( q < 0 )
			File_Check_Error("seek",f->fd,f->name,0);
		return old;
	}
	return 0;
}
#endif
;

quad_t Oj_Truncate(void *f, quad_t length) _C_FILE_BUILTIN_CODE(
{ 
	return ((quad_t (*)(void*,quad_t))
			C_Find_Method_Of(&f,Oj_Truncate_OjMID,C_RAISE_ERROR))
				(f,length); 
});

C_FILE *Cfile_Object(FILE *fd, char *name, int share)
#ifdef _C_FILE_BUILTIN
{
	static C_FUNCTABLE funcs[] = 
	{ {0},
	{Oj_Destruct_OjMID,    Cfile_Destruct},
	{Oj_Close_OjMID,       Cfile_Close},
	{Oj_Read_OjMID,        Cfile_Read},
	{Oj_Write_OjMID,       Cfile_Write},
	{Oj_Read_Line_OjMID,   Cfile_Read_Line},
	{Oj_Write_Line_OjMID,  Cfile_Write_Line},
	{Oj_Read_All_OjMID,    Cfile_Read_All},
	{Oj_Seek_OjMID,        Cfile_Seek},
	{Oj_Tell_OjMID,        Cfile_Tell},
	{Oj_Length_OjMID,      Cfile_Length},
	{Oj_Available_OjMID,   Cfile_Available},
	{Oj_Eof_OjMID,         Cfile_Eof},
	{Oj_Flush_OjMID,       Cfile_Flush},
	{0}};
	C_FILE *f = __Object(sizeof(C_FILE),funcs);
	f->fd = fd;
	f->shared = share;
	f->name = name?Str_Copy_Npl(name,-1):"<file>";
	return f;
}
#endif
;

C_FILE *Pfile_Object(FILE *fd, char *cmd, int share)
#ifdef _C_FILE_BUILTIN
{
	static C_FUNCTABLE funcs[] = 
	{ {0},
	{Oj_Destruct_OjMID,    Pfile_Destruct},
	{Oj_Close_OjMID,       Pfile_Close},
	{Oj_Read_OjMID,        Cfile_Read},
	{Oj_Write_OjMID,       Cfile_Write},
	{Oj_Read_Line_OjMID,   Cfile_Read_Line},
	{Oj_Write_Line_OjMID,  Cfile_Write_Line},
	{Oj_Eof_OjMID,         Cfile_Eof},
	{Oj_Flush_OjMID,       Cfile_Flush},
	{0}};
	C_FILE *f = __Object(sizeof(C_FILE),funcs);
	f->fd = fd;
	f->shared = share;
	f->name = cmd?Str_Copy_Npl(cmd,-1):"<command>";
	return f;
}
#endif
;

enum _C_FILE_ACCESS_FLAGS
{
	C_FILE_READ        = 1,
	C_FILE_WRITE       = 2,
	C_FILE_READWRITE   = C_FILE_READ|C_FILE_WRITE,
	C_FILE_FORWARD     = 32,
	C_FILE_TEXT        = 64, // by default is binary mode
	C_FILE_CREATE_PATH = 128, // create expected path if doesn't exists
	C_FILE_APPEND      = 256,

	//_C_FILE_NEED_EXITENT_FILE = 0x080000,
	C_FILE_OPENEXISTS  = 0x000000, // open if exists
	C_FILE_CREATENEW   = 0x010000, // error if exists
	C_FILE_OPENALWAYS  = 0x020000, // if not exists create new
	C_FILE_CREATEALWAYS= 0x030000, // if exists unlink and create new
	C_FILE_OVERWRITE   = 0x040000, // if exists truncate
	C_FILE_CREATE_MASK = 0x0f0000,

	C_FILE_CREATE      = C_FILE_READWRITE|C_FILE_CREATE_PATH|C_FILE_CREATEALWAYS,
	C_FILE_REUSE       = C_FILE_READWRITE|C_FILE_OPENALWAYS,
	C_FILE_CONSTANT    = C_FILE_READ|C_FILE_OPENEXISTS,
	C_FILE_MODIFY      = C_FILE_READWRITE|C_FILE_OPENEXISTS, 
};

void File_Check_Access_Is_Satisfied(char *path, uint_t access)
#ifdef _C_FILE_BUILTIN
{
	C_FILE_STATS st = {0};
	File_Get_Stats(path,&st,1);

	if ( (access & C_FILE_CREATE_PATH) && !st.f.exists )
		Create_Required_Dirs(path);

	if ( st.f.exists )
		if (st.f.is_directory )
			__Raise_Format(C_ERROR_IO,("file '%s' is directory",path));
		else if ( (access & C_FILE_CREATE_MASK) == C_FILE_CREATENEW  )
			__Raise_Format(C_ERROR_IO,("file '%s' already exists",path));
		else if ( (access & C_FILE_CREATE_MASK) == C_FILE_CREATEALWAYS )
			File_Unlink(path,0);
		else;
	else if ( (access & C_FILE_CREATE_MASK) == C_FILE_OPENEXISTS )
		__Raise_Format(C_ERROR_DOESNT_EXIST,("file '%s' does not exist",path));
}
#endif
;

uint_t File_Access_From_Str(char *S)
#ifdef _C_FILE_BUILTIN
{
	uint_t access = 0;
	for ( ;*S; ++S )
		switch (*S)
	{
		case '+': access |= C_FILE_WRITE; /*falldown*/
		case 'r': access |= C_FILE_READ; break;
		case 'a': access |= 
					  C_FILE_WRITE
					  |C_FILE_APPEND
					  |C_FILE_FORWARD
					  |C_FILE_OPENALWAYS;
		case 'w': access |= C_FILE_WRITE|C_FILE_OVERWRITE; break;
		case 'c': access |= C_FILE_WRITE|C_FILE_CREATEALWAYS; break;
		case 'n': access |= C_FILE_WRITE|C_FILE_CREATENEW; break;
		case 't': access |= C_FILE_TEXT; break;
		case 'P': access |= C_FILE_CREATE_PATH; break;
		default: break;
	}
	return access;
}
#endif
;

#define File_Open(Name,Access) Cfile_Open(Name,Access)

void Cfile_Remove_Nonstandard_AC(char *nonst, char *ac)
#ifdef _C_FILE_BUILTIN
{
	int ac_r = 0;
	int ac_w = 0;
	int ac_plus = 0;
	int ac_t = 0;
	/*  int ac_a = 0;
	int ac_b = 0; */

	for ( ; *nonst; ++nonst )
		switch ( *nonst )
	{
		case '+': ac_plus = 1; break;
		case 'r': ac_r = 1; break;
		case 'w': ac_w = 1; break;
		case 'c': ac_w = ac_plus = 1; break;
			/*case 'a': ac_a = 1; break;*/
		case 't': ac_t = 1; break;
			/*case 'b': ac_b = 1; break;*/
		case 'n': ac_w = ac_plus = 1; break;
	}

	if ( ac_w ) *ac++ = 'w';
	else if ( ac_r ) *ac++ = 'r';
	if ( ac_plus ) *ac++ = '+';
	if ( ac_t ) *ac++ = 't';
	else *ac++ = 'b';    
	*ac = 0;
}
#endif
;

void *Cfile_Open_Raw(char *name, char *access)
#ifdef _C_FILE_BUILTIN
{
	char ac[9];
	void *f = 0;

	// always binary mode if 't' not declared manualy
	Cfile_Remove_Nonstandard_AC(access,ac);

#ifdef __windoze
	if ( 0 != (f = _wfopen(Str_Utf8_To_Unicode(name),Str_Utf8_To_Unicode(ac))) )
#else
	if ( 0 != (f = fopen(name,ac)) )
#endif
		f = Cfile_Object(f,name,0);

	return f;
}
#endif
;

void *Pfile_Open(char *command, char *access)
#ifdef _C_FILE_BUILTIN
{
	void *f = 0;
#ifdef __windoze
	int text = 0, i;
	wchar_t ac[9] = {0};
	for ( i = 0; access[i] && i < sizeof(ac)-1; ++i )
	{
		if ( access[i] == 't' ) text = 1;
		if ( access[i] == 'b' ) text = 2;
		ac[i] = access[i];
	}
	if ( !text && i < sizeof(ac)-1 ) ac[i] = 'b'; 
	if ( 0 != (f = _wpopen(Str_Utf8_To_Unicode(command),ac)) )
#else
	if ( 0 != (f = popen(command,access)) )
#endif
		f = Pfile_Object(f,command,0);
	return f;
}
#endif
;

void *Cfile_Open(char *name, char *access)
#ifdef _C_FILE_BUILTIN
{
	void *f = 0;
	__Auto_Ptr(f)
	{
		File_Check_Access_Is_Satisfied(name,File_Access_From_Str(access));
		f = Cfile_Open_Raw(name,access);
		if ( !f )
			File_Check_Error("open file",0,name,1);
	}
	return f;
}
#endif
;

#define Cfile_Acquire(Name,Fd) Cfile_Object(Fd,Name,0)
#define Cfile_Share(Name,Fd)   Cfile_Object(Fd,Name,1)

void *Cfile_Temp()
#ifdef _C_FILE_BUILTIN
{
	FILE *f = tmpfile();
	if ( !f )
		File_Check_Error("open file",0,"tmpfile",1);
	return Cfile_Object(f,"tmpfile",0);
}
#endif
;

int Oj_Write_BOM(void *f,int bom)
#ifdef _C_FILE_BUILTIN
{
	switch( bom )
	{
	case C_BOM_DOESNT_PRESENT:
		return 0; // none
	case C_BOM_UTF16_LE:
		return Oj_Write(f,"\xff\xfe",2,2);
	case C_BOM_UTF16_BE:
		return Oj_Write(f,"\xfe\xff",2,2);
	case C_BOM_UTF8:
		return Oj_Write(f,"\xef\xbb\xbf",3,3);
	default:
		__Raise(C_ERROR_INVALID_PARAM,"bad BOM identifier");
	}

	return 0; /*fake*/
}
#endif
;

#define __Pfd_Lock(Pfd) __Interlock_Opt( (void)0, Pfd, __Pfd_Lock_In, __Pfd_Lock_Out, __Pfd_Lock_Out )

#ifdef __windoze

#define   LOCK_SH   1    /* shared lock */
#define   LOCK_EX   2    /* exclusive lock */
#define   LOCK_NB   4    /* don't block when locking */
#define   LOCK_UN   8    /* unlock */

int flock(int fd, int opt)
#ifdef _C_FILE_BUILTIN
{
	return 0;
}
#endif
;

#endif /* __windoze */

void __Pfd_Lock_In(int *pfd) 
#ifdef _C_FILE_BUILTIN
{
	STRICT_REQUIRE(pfd);

	if ( flock(*pfd,LOCK_EX) )
		__Raise_Format(C_ERROR_IO,("failed to lock fd %d: %s",*pfd,strerror(errno)));
}
#endif
;

void __Pfd_Lock_Out(int *pfd) 
#ifdef _C_FILE_BUILTIN
{
	STRICT_REQUIRE(pfd);

	if ( flock(*pfd,LOCK_UN) )
		if ( errno != EBADF )
			__Fatal("failed to unlock file");
}
#endif
;

#define __Pfd_Guard(Pfd) __Interlock_Opt( (void)0, Pfd, (void), __Pfd_Guard_Out, __Pfd_Guard_Out )
void __Pfd_Guard_Out(int *pfd) 
#ifdef _C_FILE_BUILTIN
{
	STRICT_REQUIRE(pfd);

	if ( *pfd >= 0 )
	{
		close(*pfd);
		*pfd = -1;
	}
}
#endif
;

int Oj_Copy_File(void *src, void *dst)
#ifdef _C_FILE_BUILTIN
{
	char bf[C_FILE_COPY_BUFFER_SIZE];
	int count = 0;
	int (*xread)(void*,void*,int,int) = C_Find_Method_Of(&src,Oj_Read_OjMID,C_RAISE_ERROR);
	int (*xwrite)(void*,void*,int,int) = C_Find_Method_Of(&dst,Oj_Write_OjMID,C_RAISE_ERROR);
	for ( ;; )
	{
		int i = xread(src,bf,C_FILE_COPY_BUFFER_SIZE,0);
		if ( !i ) break;
		xwrite(dst,bf,i,i);
		count += i;
	}
	return count;
}
#endif
;

#define Write_Out(Fd,Data,Count) Fd_Write_Out(Fd,Data,Count,0)
#define Write_Out_Raise(Fd,Data,Count) Fd_Write_Out(Fd,Data,Count,1)
int Fd_Write_Out(int fd, void *data, int count, int do_raise) 
#ifdef _C_FILE_BUILTIN
{
	int i;

	for ( i = 0; i < count;  )
	{
		int r = write(fd,(char*)data+i,count-i);
		if ( r >= 0 )
			i += r;
		else if ( errno != EAGAIN )
		{
			int err = errno;
			if ( do_raise )
				__Raise_Format(C_ERROR_IO,("failed to write file: %s",strerror(err)));
			return err;
		}
	}

	return 0;
}
#endif
;

#define Read_Into(Fd,Data,Count) Fd_Read_Into(Fd,Data,Count,0)
#define Read_Into_Raise(Fd,Data,Count) Fd_Read_Into(Fd,Data,Count,1)
int Fd_Read_Into(int fd, void *data, int count, int do_raise) 
#ifdef _C_FILE_BUILTIN
{
	int i;

	for ( i = 0; i < count;  )
	{
		int r = read(fd,(char*)data+i,count-i);
		if ( r > 0 )
			i += r;
		else if ( !r )
		{
			if ( do_raise )
				__Raise_Format(C_ERROR_IO,("failed to read file: %s","eof"));
			return -1;
		}
		else if ( errno != EAGAIN )
		{
			int err = errno;
			if ( do_raise )
				__Raise_Format(C_ERROR_IO,("failed to read file: %s",strerror(err)));
			return err;
		}
	}

	return 0;
}
#endif
;

#define Lseek(Fd,Pos) Fd_Lseek(Fd,Pos,0)
#define Lseek_Raise(Fd,Pos) Fd_Lseek(Fd,Pos,1)
int Fd_Lseek(int fd, quad_t pos, int do_raise)
#ifdef _C_FILE_BUILTIN
{
	if ( 0 >  
#ifdef _FILEi32
		lseek(fd,(long)pos,(pos<0?SEEK_END:SEEK_SET))
#else
		_WINPOSIX(_lseeki64,lseek64)(fd,pos,(pos<0?SEEK_END:SEEK_SET))
#endif
		)
	{
		int err = errno;
		if ( do_raise )
			__Raise_Format(C_ERROR_IO,("failed to seek file: %s",strerror(err)));
		return err;
	}
	return 0;
}
#endif
;

#define Open_File(Name,Opt) Fd_Open_File(Name,Opt,0600,0)
#define Open_File_Raise(Name,Opt) Fd_Open_File(Name,Opt,0600,1)
int Fd_Open_File(char *name, int opt, int secu, int do_raise)
#ifdef _C_FILE_BUILTIN
{
	int fd;
#ifdef __windoze
	if ( !(opt & _O_TEXT) ) opt |= _O_BINARY;
	fd = _wopen(Str_Utf8_To_Unicode(name),opt,secu);
#else
	fd = open(name,opt,secu);
#endif
	if ( fd < 0 )
	{
		int err = errno;
		if ( do_raise )
			__Raise_Format(C_ERROR_IO,("failed to open file '%s': %s",name,strerror(err)));
		return -err;
	}
	return fd;
}
#endif
;

void File_Move(char *old_name, char *new_name)
#ifdef _C_FILE_BUILTIN
{
	int err = 0;
#ifdef __windoze
	wchar_t *So = Str_Utf8_To_Unicode(old_name);
	wchar_t *Sn = Str_Utf8_To_Unicode(new_name);
	err = _wrename(So,Sn);
	__Release(Sn);
	__Release(So);
#else
	err = rename(old_name,new_name);
#endif
	if ( errno == EXDEV )
		__Auto_Release 
	{
		void *src = Cfile_Open(old_name,"r");
		void *dst = Cfile_Open(new_name,"w+P");
		Oj_Copy_File(src,dst);
		File_Unlink(old_name,0);
	}
	else if ( err < 0 )
	{
		File_Check_Error("rename",0,old_name,1); 
	}
}
#endif
;

typedef struct _C_BUFFER_FILE
{
	C_BUFFER *bf;
	int offs;
} C_BUFFER_FILE;

void C_BUFFER_FILE_Destruct(C_BUFFER_FILE *file)
#ifdef _C_FILE_BUILTIN
{
	__Unrefe(file->bf);
	__Destruct(file);
}
#endif
;

int Buffer_File_Close(C_BUFFER_FILE *file)
#ifdef _C_FILE_BUILTIN
{
	return 0;
}
#endif
;

char *Buffer_File_Read_Line(C_BUFFER_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	char *R, *S = f->bf->chars;
	int   i = f->offs;
#ifdef _DEBUG
	char *SS = f->bf->chars + f->offs;
#endif      

	if ( i == f->bf->count ) return 0;

	do
	{
		if ( S[f->offs++] == '\n' ) break;
	}
	while ( f->bf->count != f->offs );  

	R = Str_Copy_L(S+i,f->offs-i);
	S = R+f->offs-i-1;
	if ( R <= S && *S == '\n' ) 
	{
		*S-- = 0;
		if ( R <= S && *S == '\r' )
			*S = 0;
	}     
	return R;
}
#endif
;  

int Buffer_File_Read(C_BUFFER_FILE *f, void *buf, int count, int min_count)
#ifdef _C_FILE_BUILTIN
{
	if ( min_count < 0 ) min_count = count;
	if ( f->offs + min_count > f->bf->count )
		__Raise(C_ERROR_IO_EOF,"end of file");
	count = C_MIN(f->bf->count-f->offs,count);
	memcpy(buf,f->bf->at+f->offs,count);
	f->offs += count;
	return count;
}
#endif
;

int Buffer_File_Write(C_BUFFER_FILE *f, void *buf, int count, int min_count)
#ifdef _C_FILE_BUILTIN
{
	if (f->bf->count < f->offs + count )
		Buffer_Resize(f->bf,f->offs + count);
	memcpy(f->bf->at+f->offs,buf,count);
	f->offs += count;
	return count;
}
#endif
;

quad_t Buffer_File_Length(C_BUFFER_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	return f->bf->count;
}
#endif
;

quad_t Buffer_File_Available(C_BUFFER_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	if ( f->offs >= f->bf->count )
		return 0;
	return f->bf->count - f->offs;
}
#endif
;

int Buffer_File_Eof(C_BUFFER_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	if ( f->offs >= f->bf->count )
		return 1;
	return 0;
}
#endif
;

quad_t Buffer_File_Seek(C_BUFFER_FILE *f, quad_t pos, int whence)
#ifdef _C_FILE_BUILTIN
{
	quad_t old = f->offs;
	if ( whence == SEEK_SET )
		f->offs = (int)pos;
	else if ( whence == SEEK_CUR )
		f->offs += (int)pos;
	else if ( whence == SEEK_END )
		f->offs = f->bf->count + (int)pos;
	if ( f->offs < 0 ) 
	{
		f->offs = 0;
		__Raise(C_ERROR_IO,"negative file offset");
	}
	return old;
}
#endif
;

quad_t Buffer_File_Tell(C_BUFFER_FILE *f)
#ifdef _C_FILE_BUILTIN
{
	return f->offs;
}
#endif
;

void Buffer_File_Flush()
#ifdef _C_FILE_BUILTIN
{
}
#endif
;

quad_t Buffer_File_Truncate(C_BUFFER_FILE *f, quad_t len)
#ifdef _C_FILE_BUILTIN
{
	if ( len >= 0 && len < f->bf->count ) 
		Buffer_Resize(f->bf,(int)len);
	return f->bf->count;
}
#endif
;

void *Buffer_As_File(C_BUFFER *bf)
#ifdef _C_FILE_BUILTIN
{
	static C_FUNCTABLE funcs[] = 
	{ {0},
	{Oj_Destruct_OjMID,    C_BUFFER_FILE_Destruct},
	{Oj_Close_OjMID,       Buffer_File_Close},
	{Oj_Read_OjMID,        Buffer_File_Read},
	{Oj_Write_OjMID,       Buffer_File_Write},
	{Oj_Available_OjMID,   Buffer_File_Available},
	{Oj_Eof_OjMID,         Buffer_File_Eof},
	{Oj_Length_OjMID,      Buffer_File_Length},
	{Oj_Seek_OjMID,        Buffer_File_Seek},
	{Oj_Tell_OjMID,        Buffer_File_Tell},
	{Oj_Flush_OjMID,       Buffer_File_Flush},
	{Oj_Read_Line_OjMID,   Buffer_File_Read_Line},
	{Oj_Truncate_OjMID,    Buffer_File_Truncate},
	{0}
	};
	C_BUFFER_FILE *file = __Object(sizeof(C_BUFFER_FILE),funcs);
	if ( !bf ) bf = Buffer_Init(0);
	file->bf = __Refe(bf);
	return file;
}
#endif
;

void C_MEMORY_FILE_Destruct(C_BUFFER_FILE *file)
#ifdef _C_FILE_BUILTIN
{
	free(file->bf);
	__Destruct(file);
}
#endif
;

int Memory_File_Write(C_BUFFER_FILE *f, void *buf, int count, int min_count)
#ifdef _C_FILE_BUILTIN
{
	if ( f->bf->count < f->offs + count )
		__Raise(C_ERROR_OUT_OF_RANGE,"out of memory range");
	memcpy(f->bf->at+f->offs,buf,count);
	f->offs += count;
	return count;
}
#endif
;

void *Memory_As_File(void *mem, int mem_len)
#ifdef _C_FILE_BUILTIN
{
	static C_FUNCTABLE funcs[] = 
	{ {0},
	{Oj_Destruct_OjMID,    C_MEMORY_FILE_Destruct},
	{Oj_Close_OjMID,       Buffer_File_Close},
	{Oj_Read_OjMID,        Buffer_File_Read},
	{Oj_Write_OjMID,       Memory_File_Write},
	{Oj_Available_OjMID,   Buffer_File_Available},
	{Oj_Eof_OjMID,         Buffer_File_Eof},
	{Oj_Length_OjMID,      Buffer_File_Length},
	{Oj_Seek_OjMID,        Buffer_File_Seek},
	{Oj_Tell_OjMID,        Buffer_File_Tell},
	{Oj_Flush_OjMID,       Buffer_File_Flush},
	{Oj_Read_Line_OjMID,   Buffer_File_Read_Line},
	{0}
	};

	C_BUFFER_FILE *file = __Object(sizeof(C_BUFFER_FILE),funcs);
	file->bf = __Zero_Malloc_Npl(sizeof(C_BUFFER));
	file->bf->at = mem;
	file->bf->count = mem_len;
	return file;
}
#endif
;

void Oj_Print(void *foj, char *S)
#ifdef _C_FILE_BUILTIN
{
	int S_len = S?strlen(S):0;
	if ( S_len )
		Oj_Write_Full(foj,S,S_len);
}
#endif
;

void Oj_Printf(void *foj, char *fmt, ...)
#ifdef _C_FILE_BUILTIN
{
	__Auto_Release
	{
		va_list va;
		char *text;
		va_start(va,fmt);
		text = __Pool(C_Format_(fmt,va));
		va_end(va);
		Oj_Print(foj,text);
	}
}
#endif
;

void Oj_Fill(void *fobj, byte_t val, int count)
#ifdef _C_FILE_BUILTIN
{
	byte_t bf[512];

	REQUIRE(count >= 0);
	memset(bf,val,sizeof(bf));
	while ( count > 0 )
	{
		int L = C_MIN(count,sizeof(bf));
		Oj_Write_Full(fobj,bf,L);
		count -= L;
	}
}
#endif
;

int Oj_Apply_File(void *foj, void *accu, void (*algo)(void *accu,void *buf, int L))
#ifdef _C_FILE_BUILTIN
{
	char bf[C_FILE_COPY_BUFFER_SIZE];
	int count = 0;
	int (*xread)(void*,void*,int,int) = C_Find_Method_Of(&foj,Oj_Read_OjMID,C_RAISE_ERROR);
	for ( ;; )
	{
		int i = xread(foj,bf,C_FILE_COPY_BUFFER_SIZE,0);
		if ( !i ) break;
		algo(accu,bf,i);
		count += i;
	}
	return count;
}
#endif
;

_C_FILE_EXTERN char Oj_Digest_File_Update_OjMID[] _C_FILE_BUILTIN_CODE( = "digest-file-update/@*"); 
void Oj_Digest_File_Update(void *dgst,void *foj) _C_FILE_BUILTIN_CODE(
{ 
	void(*update)(void*,void*,int) = C_Find_Method_Of(&dgst,Oj_Digest_Update_OjMID,C_RAISE_ERROR);
	Oj_Apply_File(foj,dgst,update); 
});

void File_Update_Digest(void *dgst, char *filename)
#ifdef _C_FILE_BUILTIN
{
	__Auto_Release Oj_Digest_File_Update(dgst,Cfile_Open(filename,"r"));
}
#endif
;

#endif /* C_once_E9479D04_5D69_4A1A_944F_0C99A852DC0B */

