Where we got the dictionaries
=============================

This directory contains plain-text dictionaries. Requirements:

* A dictionary is encoded as UTF-8.
* Each word is on its own line.
* Lines are separated by `\n`.
* Words must all conform to the PCRE `[-_’'\p{L}\p{N}]+`.
* Empty lines are ignored.

Here's how we created them, in recipe format:

en
--

1. Download
[https://github.com/first20hours/google-10000-english](https://github.com/first20hours/google-10000-english)
2. Rename it: `cp https://github.com/first20hours/google-10000-english/blob/master/google-10000-english.txt en-step2.txt`
3. Remove short words: `grep '...' < en-step2.txt > en-step3.txt`
4. Clean up: `cp en-step3.txt en.txt; rm -f en-step*.txt google-10000-english.txt`
