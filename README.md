# chromedriver-logs

Usage:

```
stack build
cat chromedriver.log | stack exec chromedriver-logs-exe
```

chromedriver (the tool for programmatic interaction with Chrome) doesn't have an output format amenable to analysis. This tool:

- Outputs JSON
- Keeps track of commands and their response times
- Streams log lines
- Ignores junk lines

[![asciicast](https://asciinema.org/a/44dRKLg0E2Mp9CXrZb113IHAK.png)](https://asciinema.org/a/44dRKLg0E2Mp9CXrZb113IHAK)
