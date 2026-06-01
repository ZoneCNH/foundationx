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

func TestAPIDocsPreservePublicBehaviorContracts(t *testing.T) {
	docs, err := os.ReadFile(filepath.Join("..", "docs", "api.md"))
	if err != nil {
		t.Fatalf("read docs/api.md: %v", err)
	}
	text := string(docs)

	for _, want := range []string{
		"`Error.WithRetryable` 会修改当前 `*Error` 并返回同一个指针",
		"`HealthStatus.WithMetadata` 会复制已有 metadata 并返回更新后的状态，不会修改调用它的原始 `HealthStatus`",
		"`metadata` 在 Go 值为 nil 时仍输出为空 JSON 对象",
		"是否超过 `MaxAttempts` 由调用方的执行循环判断",
		"非空 `SecretString` 在字符串格式化、`Sanitize` 和 JSON 输出中默认返回 `***`",
	} {
		if !strings.Contains(text, want) {
			t.Errorf("docs/api.md does not preserve public behavior contract %q", want)
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
