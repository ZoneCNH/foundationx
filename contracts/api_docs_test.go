package contracts

import (
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"
)

func TestAPIDocsMentionExportedSurface(t *testing.T) {
	docs, err := os.ReadFile(filepath.Join("..", "docs", "api.md"))
	if err != nil {
		t.Fatalf("read docs/api.md: %v", err)
	}
	text := string(docs)

	for _, name := range exportedSurface(t, filepath.Join("..", "pkg", "foundationx")) {
		if !strings.Contains(text, "`"+name+"`") {
			t.Errorf("docs/api.md does not mention exported API %q", name)
		}
	}
}

func exportedSurface(t *testing.T, dir string) []string {
	t.Helper()

	set := token.NewFileSet()
	pkgs, err := parser.ParseDir(set, dir, func(info os.FileInfo) bool {
		return !strings.HasSuffix(info.Name(), "_test.go")
	}, 0)
	if err != nil {
		t.Fatalf("parse package dir %s: %v", dir, err)
	}

	pkg, ok := pkgs["foundationx"]
	if !ok {
		t.Fatalf("package foundationx not found in %s", dir)
	}

	names := map[string]bool{}
	for _, file := range pkg.Files {
		for _, decl := range file.Decls {
			switch decl := decl.(type) {
			case *ast.GenDecl:
				for _, spec := range decl.Specs {
					switch spec := spec.(type) {
					case *ast.TypeSpec:
						addExported(names, spec.Name.Name)
					case *ast.ValueSpec:
						for _, name := range spec.Names {
							addExported(names, name.Name)
						}
					}
				}
			case *ast.FuncDecl:
				if decl.Recv == nil {
					addExported(names, decl.Name.Name)
					continue
				}
				receiver := receiverName(decl.Recv)
				if receiver != "" && ast.IsExported(receiver) && ast.IsExported(decl.Name.Name) {
					names[receiver+"."+decl.Name.Name] = true
				}
			}
		}
	}

	sorted := make([]string, 0, len(names))
	for name := range names {
		sorted = append(sorted, name)
	}
	sort.Strings(sorted)
	return sorted
}

func addExported(names map[string]bool, name string) {
	if ast.IsExported(name) {
		names[name] = true
	}
}

func receiverName(fields *ast.FieldList) string {
	if fields == nil || len(fields.List) != 1 {
		return ""
	}
	switch expr := fields.List[0].Type.(type) {
	case *ast.Ident:
		return expr.Name
	case *ast.StarExpr:
		if ident, ok := expr.X.(*ast.Ident); ok {
			return ident.Name
		}
	}
	return ""
}
