MD_FILES:=$(shell find commands topics -name '*.md')
TEXT_FILES:=$(patsubst %.md,tmp/%.txt,$(MD_FILES))
SPELL_FILES:=$(patsubst %.txt,%.spell,$(TEXT_FILES))

spell: tmp/commands tmp/topics $(SPELL_FILES)
	find tmp -name '*.spell' | xargs cat > tmp/all.spell
	cat tmp/all.spell
	test -s tmp/all.spell && exit 1

$(TEXT_FILES): tmp/%.txt: %.md
	./bin/text $< > $@

$(SPELL_FILES): %.spell: %.txt tmp/dict
	aspell -a --extra-dicts=./tmp/dict 2>/dev/null < $< | \
		awk -v FILE=$(patsubst tmp/%.spell,%.md,$@) '/^\&/ { print FILE, $$2 }' | \
		sort -f | uniq > $@

tmp/commands:
	mkdir -p tmp/commands

tmp/topics:
	mkdir -p tmp/topics

tmp/commands.txt: commands.json
	ruby -rjson -e 'puts JSON.parse(File.read("$<")).keys.map { |str| str.split(/[ -]/) }.flatten(1)' > $@

tmp/dict: wordlist tmp/commands.txt
	cat $^ | aspell --lang=en create master ./$@

clean:
	rm -rf tmp/*

.PHONY: clean
