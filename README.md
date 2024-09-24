# howto

`howto` is a small helper for the Linux shell command line.  When you're stuck with which command to type next, aren't sure how to achieve what you need, or don't know whether a tool exists to do it, `howto` will provide you with one or more options to explore. 


`howto` is heavily inspired by [thomas-enders-TNG's `please-cli`](https://github.com/TNG/please-cli), which performs the same basic function but does it better (and with much more functionality) with ChatGPT using an OpenAI API key. By contrast, `howto` uses a small local LLM via Ollama, with a prompt to coax it into returning what's needed. This has the benefits of (+) keeping your discussions private and (+) working free of charge, at the expense of (-) local resources (-) being worse at its job. 

The default model is [`qwen2.5-coder:7b`](https://ollama.com/library/qwen2.5-coder), which seems to have a good balance between resource usage on a small laptop, and accuracy. It's impefect and has some limitations, like suggesting commands which don't really exist. To balance this out, `howto` will prompt it to list multiple ideas if appropriate. You can specify an alternative model to use with the option `-m [modelname]` or `--model [modelname]`.

## Usage: 

howto [ options ] [ query ]

Options:
  -e, --explain    Explain the command suggestions to the user
  -m, --model      Specify a specific model to be used with Ollama. The default is qwen2.5-coder:7b.
  -v, --version    Display version info
  -h, --help       Display this help message

To translate a purpose into a command, simply provide your purpose, for example,

1.  to help you remember which options to use in a familiar command:
  ``` Example
  $> howto list all files in the present directory sorted by time
  ls -lt
  ```

2. `find`-`exec` syntax:
``` Example
  $> howto convert all pdfs in current directory to text\?
  find . -maxdepth 1 -type f -name "*.pdf" -exec pdftotext {} \;
  ```

3. `sed` syntax:
  ``` Example
  $> howto use sed to replace US dates with ISO format dates
  sed 's/\([0-9]\{1,2\}\)\/\([0-9]\{1,2\}\)\/\([0-9]\{4\}\)/\3-\2-\1/g'
  ```


## Explain mode

In default usage, `howto` should output a very brief response. For a fuller explanation of what the suggested commands do, Use the option `-e` or `--explain`, for example:

```
$>howto -e search recursively for dates and times, listing hits in ascending order
**OPTIONS:**  
1) find -type f -exec grep -oE '([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})' {} + | sort  
2) locate -b '\*.*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\*' | sort  

**Explanation:**  
1) `find -type f -exec grep -oE '([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})' {} + | sort`:  
   - `find / -type f 2>/dev/null`: Recursively searches for all files in the directory hierarchy, ignoring error messages (e.g., permission denied).  
   - `-exec grep -oE '...' {} +`: For each file found, it executes a regular expression search to find date and time patterns. The `-o` option ensures only matching parts of lines are output, and `-E` enables extended regular expressions.  
   - `| sort`: Sorts the output in ascending order.

2) `locate -b '\*.*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\*' | sort`:  
   - `locate -b '\*.*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\*'`: Uses the `locate` command to find all filenames containing a date and time pattern. The `-b` option ensures only basename is returned, which helps in reducing output noise.  
   - `| sort`: Sorts the output in ascending order.

The second option (`locate`) is generally faster for large file systems as it uses an indexed database of filenames, while `find` needs to traverse the filesystem tree directly.
```

## Warnings

Please do be careful: this is just a helper script, not a replacement for thought. It should go without saying that you should not blindly execute commands generated by a low-powered AI. 

After beginning a query with "howto", you may find yourself ending your query with a question mark, which is natural. Since `?` is a wildcard in bash, that creates a problem. You'll have to escape either the character itself, or your urge to type it. 


## Installation

Requires Ollama and the model to be used:

1. First, install **Ollama**, which is used to run the model. Follow Ollama's installation instructions:
[ollama on GitHub](https://github.com/ollama/ollama)  |  [ollama.com](https://ollama.com/)

2. Pull the default model `qwen2.5-coder:7b` itself: `ollama pull qwen2.5-coder:7b`. Alternatively, pull the model of your choice and specify it with the `-m` or `--model` option.

3. For ease of use, create a symlink to allow easy execution, for example as follows (or : `ln -s path/to/howto.sh /usr/local/bin/howto`

