package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"go/ast"
	"go/parser"
	"go/printer"
	"go/token"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type pkgInfo struct {
	ImportPath string
	Name       string
	Dir        string
	GoFiles    []string
}

func main() {
	dec := json.NewDecoder(bufio.NewReader(os.Stdin))
	var lines []string
	for {
		var info pkgInfo
		if err := dec.Decode(&info); err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			fatal(err)
		}
		if info.ImportPath == "" || info.Dir == "" {
			continue
		}
		pkgLines, err := packageLines(info)
		if err != nil {
			fatal(err)
		}
		lines = append(lines, pkgLines...)
	}
	sort.Strings(lines)
	for _, line := range lines {
		fmt.Println(line)
	}
}

func packageLines(info pkgInfo) ([]string, error) {
	fset := token.NewFileSet()
	var lines []string
	for _, name := range info.GoFiles {
		if strings.HasSuffix(name, "_test.go") {
			continue
		}
		path := filepath.Join(info.Dir, name)
		file, err := parser.ParseFile(fset, path, nil, parser.ParseComments)
		if err != nil {
			return nil, err
		}
		for _, decl := range file.Decls {
			switch d := decl.(type) {
			case *ast.GenDecl:
				for _, spec := range d.Specs {
					switch s := spec.(type) {
					case *ast.TypeSpec:
						if !ast.IsExported(s.Name.Name) {
							continue
						}
						lines = append(lines, fmt.Sprintf("%s type %s %s", info.ImportPath, s.Name.Name, exprString(fset, s.Type)))
						if st, ok := s.Type.(*ast.StructType); ok {
							for _, field := range st.Fields.List {
								for _, name := range field.Names {
									if ast.IsExported(name.Name) {
										tag := ""
										if field.Tag != nil {
											tag = " " + field.Tag.Value
										}
										lines = append(lines, fmt.Sprintf("%s field %s.%s %s%s", info.ImportPath, s.Name.Name, name.Name, exprString(fset, field.Type), tag))
									}
								}
							}
						}
					case *ast.ValueSpec:
						kind := strings.ToLower(d.Tok.String())
						for _, name := range s.Names {
							if ast.IsExported(name.Name) {
								typ := "<inferred>"
								if s.Type != nil {
									typ = exprString(fset, s.Type)
								}
								lines = append(lines, fmt.Sprintf("%s %s %s %s", info.ImportPath, kind, name.Name, typ))
							}
						}
					}
				}
			case *ast.FuncDecl:
				if d.Recv == nil {
					if ast.IsExported(d.Name.Name) {
						lines = append(lines, fmt.Sprintf("%s func %s%s", info.ImportPath, d.Name.Name, funcSig(fset, d.Type)))
					}
					continue
				}
				if ast.IsExported(d.Name.Name) {
					lines = append(lines, fmt.Sprintf("%s method %s.%s%s", info.ImportPath, recvString(fset, d.Recv), d.Name.Name, funcSig(fset, d.Type)))
				}
			}
		}
	}
	return lines, nil
}

func recvString(fset *token.FileSet, recv *ast.FieldList) string {
	if recv == nil || len(recv.List) == 0 {
		return ""
	}
	s := exprString(fset, recv.List[0].Type)
	return strings.TrimPrefix(s, "*")
}

func funcSig(fset *token.FileSet, typ *ast.FuncType) string {
	params := fieldListString(fset, typ.Params)
	results := fieldListString(fset, typ.Results)
	if results == "" {
		return "(" + params + ")"
	}
	if strings.Contains(results, ",") || strings.Contains(results, " ") {
		return "(" + params + ") (" + results + ")"
	}
	return "(" + params + ") " + results
}

func fieldListString(fset *token.FileSet, list *ast.FieldList) string {
	if list == nil {
		return ""
	}
	var parts []string
	for _, field := range list.List {
		typ := exprString(fset, field.Type)
		if len(field.Names) == 0 {
			parts = append(parts, typ)
			continue
		}
		for _, name := range field.Names {
			parts = append(parts, name.Name+" "+typ)
		}
	}
	return strings.Join(parts, ", ")
}

func exprString(fset *token.FileSet, expr ast.Expr) string {
	var b bytes.Buffer
	if err := printer.Fprint(&b, fset, expr); err != nil {
		return "<print-error>"
	}
	return strings.Join(strings.Fields(b.String()), " ")
}

func fatal(v any) { fmt.Fprintln(os.Stderr, "api snapshot:", v); os.Exit(1) }
