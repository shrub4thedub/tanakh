# tanakh

simple command line tool for searching the hebrew bible

## setup

requires python3 and the sefaria export data

```bash
# generate the text database (takes a few minutes)
python3 tanakh.py

# search for verses
./tanakh.sh genesis 1:1
./tanakh.sh psalms 23:4
./tanakh.sh genesis 1

# works with lowercase and whole chapters
./tanakh.sh song of songs 2:1
```

outputs hebrew first, then english, no formatting

that's it