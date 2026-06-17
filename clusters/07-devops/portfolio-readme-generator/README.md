# portfolio-readme-generator

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Generates consistent, professional README files for security tooling and research repos.
Enforces a fixed section order, reads the code before writing, and always includes the
authorised-use disclaimer for offensive tools. Calibrated to the quality bar set by
Phosphor, Slice-N-Dice, and DNSResolver.

---

## What this skill does

Reads the actual repo code first, then produces a README with a fixed structure:
description → features (only what exists) → requirements → installation → usage →
roadmap → disclaimer → licence. Applies British English and human-rewrite style rules.

The authorised-use disclaimer is mandatory for all security tools — no exceptions.

---

## When to use it

- A repo has no README or only a placeholder
- A repo's existing README is inaccurate or incomplete
- You are preparing a repo for portfolio publication and it needs a consistent look

---

## Installation

### Claude Code

```bash
cp -r clusters/07-devops/portfolio-readme-generator ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#portfolio-readme-generator
```

### MCP client

Register the grimoire MCP server — this skill is exposed as tool `portfolio_readme_generator`.

> **Note:** This is an `action` type skill — available as MCP tool, prompt file, and Claude Code.


---

## How to invoke it in a session

```
/portfolio-readme-generator
Repo: CLion-nova-bof-template
Type: security tool (BOF development)
Status: working
```

Or inline:

```
Write a README for this repo. It's a DNS resolver tool for finding dangling CNAME records.
[paste or point to the code]
```

---

## Disclaimer template

Always included for security tooling:

> This tool is intended for use in authorised security assessments, research, and
> educational purposes only. Usage against systems you do not own or have explicit
> written permission to test is illegal. The author assumes no liability for misuse.

---

## Per-language skeleton examples

Reference structures for the three most common repo types in this portfolio.
Each skeleton shows the section order and representative content — adapt to the actual repo.

---

### Python CLI tool

```markdown
# tool-name

One-sentence description of what it does and why.

## Features

- Feature A (what it catches / what it fixes)
- Feature B

## Requirements

- Python 3.9+
- `pip install requests` (or list key deps)

## Installation

```bash
git clone -b v1.2.0 https://github.com/incendiary/tool-name.git
cd tool-name
pip install -r requirements.txt
```

## Usage

```bash
python tool.py --target example.com --output results.json
python tool.py --help
```

## Roadmap

- [x] Core feature
- [ ] Planned enhancement

## Disclaimer

> This tool is intended for use in authorised security assessments, research, and
> educational purposes only. Usage against systems you do not own or have explicit
> written permission to test is illegal. The author assumes no liability for misuse.

## Licence

MIT
```

---

### C# Windows tool

```markdown
# ToolName

One-sentence description — what it does on Windows and in what context.

## Features

- Feature A
- Feature B

## Requirements

- Windows 10/11 or Windows Server 2019+
- .NET 8.0 Runtime ([download](https://dotnet.microsoft.com/download))
- Administrator privileges (if required)

## Build

```bash
dotnet build -c Release
# Output: bin/Release/net8.0/ToolName.exe
```

## Usage

```cmd
ToolName.exe --target <pid> --output dump.bin
ToolName.exe --help
```

## Roadmap

- [x] Core injection/enumeration/analysis feature
- [ ] Planned enhancement

## Disclaimer

> This tool is intended for use in authorised security assessments, research, and
> educational purposes only. Usage against systems you do not own or have explicit
> written permission to test is illegal. The author assumes no liability for misuse.

## Licence

MIT
```

---

### C++ BOF (Beacon Object File)

```markdown
# bof-name

One-sentence description — what the BOF does, which C2 framework it targets.

## Features

- Feature A (e.g. enumerates X without touching disk)
- Feature B

## Requirements

- Cobalt Strike 4.x or Havoc C2
- Visual Studio 2019+ or mingw-w64 cross-compiler
- x64 target (x86 not supported)

## Build

```bash
# mingw cross-compile
x86_64-w64-mingw32-gcc -o bof-name.o -c bof-name.c \
    -masm=intel -Wall -DBOF

# Or with the provided Makefile
make
```

## Usage

**Cobalt Strike — load via Aggressor:**

```
beacon> bof-name <arg1> <arg2>
```

**Aggressor script:**

```
beacon_command_register("bof-name", "Short description",
    "Usage: bof-name <arg1> <arg2>");
alias bof-name {
    local('$bdata');
    $bdata = bof_pack($1, "zz", $2, $3);
    beacon_inline_execute($1, readb(script_resource("bof-name.o")), "go", $bdata);
}
```

## Roadmap

- [x] Initial implementation
- [ ] x86 support

## Disclaimer

> This tool is intended for use in authorised penetration tests and red team engagements
> only. A signed scope of work must be in place before use. The author assumes no
> liability for misuse.

## Licence

MIT
```

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Add README linter to check structure compliance post-generation
- [x] Add per-language examples (Python CLI, C# Windows tool, C++ BOF)
- [ ] Test on 5 repos
- [x] Ship: copy to `~/.claude/skills/portfolio-readme-generator/`
