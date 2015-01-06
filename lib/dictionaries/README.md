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

ru
--

1. Copy/paste the top 10,000 words from [http://ru.wiktionary.org/wiki/Приложение:Список частотности по НКРЯ: Устная речь 1—1000](http://ru.wiktionary.org/wiki/%D0%9F%D1%80%D0%B8%D0%BB%D0%BE%D0%B6%D0%B5%D0%BD%D0%B8%D0%B5:%D0%A1%D0%BF%D0%B8%D1%81%D0%BE%D0%BA_%D1%87%D0%B0%D1%81%D1%82%D0%BE%D1%82%D0%BD%D0%BE%D1%81%D1%82%D0%B8_%D0%BF%D0%BE_%D0%9D%D0%9A%D0%A0%D0%AF:_%D0%A3%D1%81%D1%82%D0%BD%D0%B0%D1%8F_%D1%80%D0%B5%D1%87%D1%8C_1%E2%80%941000) into "ru.txt". Be sure not to copy the numbers or punctuation marks.
