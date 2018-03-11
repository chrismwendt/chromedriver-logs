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

<script src="https://asciinema.org/a/44dRKLg0E2Mp9CXrZb113IHAK.js" id="asciicast-44dRKLg0E2Mp9CXrZb113IHAK" async></script>
