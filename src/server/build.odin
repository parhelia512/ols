package server

import "core:path/filepath"
import path "core:path/slashpath"
import "core:os"
import "core:fmt"
import "core:odin/parser"
import "core:odin/ast"
import "core:log"
import "core:odin/tokenizer"
import "core:strings"
import "core:mem"
import "core:runtime"

import "shared:common"


symbol_collection: SymbolCollection

files: [dynamic]string

platform_os: map[string]bool = {
	"windows" = true,
	"linux" = true, 
	"essence" = true,
	"js" = true,
	"freebsd" = true,
	"darwin" = true,
	"wasm32" = true,
}

os_enum_to_string: map[runtime.Odin_OS_Type]string = {
	.Windows = "windows",
	.Darwin = "darwin",
	.Linux = "linux",
	.Essence = "essence",
	.FreeBSD = "freebsd",
	.WASI = "wasi",
	.JS = "js",
	.Freestanding = "freestanding",
}

walk_directory :: proc(info: os.File_Info, in_err: os.Errno) -> (err: os.Errno, skip_dir: bool) {
	if info.is_dir {
		return 0, true
	}

	if filepath.ext(info.name) != ".odin" {
		return 0, false
	}

	last_underscore_index := strings.last_index(info.name, "_")
	last_dot_index := strings.last_index(info.name, ".")

	if last_underscore_index + 1 < last_dot_index {
		name_between := info.name[last_underscore_index + 1:last_dot_index]

		if _, ok := platform_os[name_between]; ok {
			if name_between != os_enum_to_string[ODIN_OS] {	
				return 0, false
			}
		}
	}

	forward, _ := filepath.to_slash(info.fullpath, context.temp_allocator)

	append(&files, strings.clone(forward, context.allocator))

	return 0, false
}

/*
try_build_package :: proc(pkg: string) {

	
	


}

evict_old_build_packages :: proc() {

}
*/

/*


build_static_index :: proc(allocator := context.allocator, config: ^common.Config) {
	symbol_collection = make_symbol_collection(allocator, config)

	files = make([dynamic]string, context.allocator)

	for k, v in config.collections {
		filepath.walk(v, walk_static_index_build)
	}

	when ODIN_OS == .Windows {
		slashed, _ := filepath.to_slash(os.get_current_directory(context.temp_allocator), context.temp_allocator)
	} else {
		slashed, _ := filepath.to_slash(os.get_current_directory(), context.temp_allocator)
	}

	builtin_package := path.join(elems = {slashed, "builtin"}, allocator = context.allocator)

	filepath.walk(builtin_package, walk_static_index_build)

	temp_arena: mem.Arena

	mem.init_arena(&temp_arena, make([]byte, mem.Megabyte*100))

	context.allocator = mem.arena_allocator(&temp_arena)

	for fullpath in files {
		data, ok := os.read_entire_file(fullpath, context.allocator)

		if !ok {
			log.errorf("failed to read entire file for indexing %v", fullpath)
			continue
		}

		p := parser.Parser {
			err = log_error_handler,
			warn = log_warning_handler,
			flags = {.Optional_Semicolons},
		}

		dir := filepath.base(filepath.dir(fullpath, context.allocator))

		pkg := new(ast.Package)
		pkg.kind = .Normal
		pkg.fullpath = fullpath
		pkg.name = dir

		if dir == "runtime" {
			pkg.kind = .Runtime
		}

		file := ast.File {
			fullpath = fullpath,
			src = string(data),
			pkg = pkg,
		}

		ok = parser.parse_file(&p, &file)

		if !ok {
			log.info(pkg)
			log.errorf("error in parse file for indexing %v", fullpath)
		}

		uri := common.create_uri(fullpath, context.allocator)

		collect_symbols(&symbol_collection, file, uri.uri)

		free_all(context.allocator)
	}

	indexer.index = make_memory_index(symbol_collection)

	if config.enable_references {
		for fullpath in files {
			data, ok := os.read_entire_file(fullpath, context.allocator)

			if !ok {
				log.errorf("failed to read entire file for indexing %v", fullpath)
				continue
			}

			//TODO(daniel): Implement path code to handle whether paths are contained in core
			if !config.enable_std_references && (strings.contains(fullpath, "Odin/core") || strings.contains(fullpath, "odin/core") || strings.contains(fullpath, "Odin/vendor") || strings.contains(fullpath, "odin/vendor")) {
				continue;
			}

			p := parser.Parser {
				err = log_error_handler,
				warn = log_warning_handler,
				flags = {.Optional_Semicolons},
			}

			dir := filepath.base(filepath.dir(fullpath, context.allocator))

			pkg := new(ast.Package)
			pkg.kind = .Normal
			pkg.fullpath = fullpath
			pkg.name = dir

			if dir == "runtime" {
				pkg.kind = .Runtime
			}

			file := ast.File {
				fullpath = fullpath,
				src = string(data),
				pkg = pkg,
			}

			ok = parser.parse_file(&p, &file)

			if !ok {
				log.info(pkg)
				log.errorf("error in parse file for indexing %v", fullpath)
			}

			uri := common.create_uri(fullpath, context.allocator)

			{
				context.temp_allocator = context.allocator
				collect_references(&symbol_collection, file, uri.uri)
			}

			free_all(context.allocator)

			delete(fullpath, allocator)
		}
	}

	delete(files)
	delete(temp_arena.data)

	indexer.index = make_memory_index(symbol_collection)
}
*/
free_static_index :: proc() {
	delete_symbol_collection(symbol_collection)
}

log_error_handler :: proc(pos: tokenizer.Pos, msg: string, args: ..any) {
	log.warnf("%v %v %v", pos, msg, args)
}

log_warning_handler :: proc(pos: tokenizer.Pos, msg: string, args: ..any) {
	log.warnf("%v %v %v", pos, msg, args)
}
