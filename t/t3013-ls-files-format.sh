#!/bin/sh

test_description='git ls-files --format test'

TEST_PASSES_SANITIZE_LEAK=true
. ./test-lib.sh

for flag in -s -o -k -t --resolve-undo --deduplicate --eol
do
	test_expect_success "usage: --format is incompatible with $flag" '
		test_expect_code 129 git ls-files --format="%(objectname)" $flag
	'
done

test_expect_success 'setup' '
	printf "LINEONE\nLINETWO\nLINETHREE\n" >o1.txt &&
	printf "LINEONE\r\nLINETWO\r\nLINETHREE\r\n" >o2.txt &&
	printf "LINEONE\r\nLINETWO\nLINETHREE\n" >o3.txt &&
	git add o?.txt &&
	oid=$(git hash-object o1.txt) &&
	git update-index --add --cacheinfo 120000 $oid o4.txt &&
	git update-index --add --cacheinfo 160000 $oid o5.txt &&
	git update-index --add --cacheinfo 100755 $oid o6.txt &&
	git commit -m base
'

test_expect_success 'git ls-files --format objectmode v.s. -s' '
	git ls-files -s >files &&
	cut -d" " -f1 files >expect &&
	git ls-files --format="%(objectmode)" >actual &&
	test_cmp expect actual
'

test_expect_success 'git ls-files --format objectname v.s. -s' '
	git ls-files -s >files &&
	cut -d" " -f2 files >expect &&
	git ls-files --format="%(objectname)" >actual &&
	test_cmp expect actual
'

test_expect_success 'git ls-files --format v.s. --eol' '
	git ls-files --eol >tmp &&
	sed -e "s/	/ /g" -e "s/  */ /g" tmp >expect 2>err &&
	test_must_be_empty err &&
	git ls-files --format="i/%(eolinfo:index) w/%(eolinfo:worktree) attr/%(eolattr) %(path)" >actual 2>err &&
	test_must_be_empty err &&
	test_cmp expect actual
'

test_expect_success 'git ls-files --format path v.s. -s' '
	git ls-files -s >files &&
	cut -f2 files >expect &&
	git ls-files --format="%(path)" >actual &&
	test_cmp expect actual
'

test_expect_success 'git ls-files --format with -m' '
	echo change >o1.txt &&
	cat >expect <<-\EOF &&
	o1.txt
	o4.txt
	o5.txt
	o6.txt
	EOF
	git ls-files --format="%(path)" -m >actual &&
	test_cmp expect actual
'

test_expect_success 'git ls-files --format with -d' '
	echo o7 >o7.txt &&
	git add o7.txt &&
	rm o7.txt &&
	cat >expect <<-\EOF &&
	o4.txt
	o5.txt
	o6.txt
	o7.txt
	EOF
	git ls-files --format="%(path)" -d >actual &&
	test_cmp expect actual
'

test_expect_success 'git ls-files --format v.s -s' '
	git ls-files --stage >expect &&
	git ls-files --format="%(objectmode) %(objectname) %(stage)%x09%(path)" >actual &&
	test_cmp expect actual
'

test_expect_success 'git ls-files --format with --debug' '
	git ls-files --debug >expect &&
	git ls-files --format="%(path)" --debug >actual &&
	test_cmp expect actual
'

test_expect_success 'git ls-files --format with skipworktree' '
	mkdir dir1 dir2 &&
	echo "file1" >dir1/file1.txt &&
	echo "file2" >dir2/file2.txt &&
	git add dir1 dir2 &&
	git commit -m skipworktree &&
	git sparse-checkout set dir1 &&
	git ls-files --format="%(path) %(skipworktree)" >actual &&
	cat >expect <<-\EOF &&
	dir1/file1.txt false
	dir2/file2.txt true
	o1.txt false
	o2.txt false
	o3.txt false
	o4.txt false
	o5.txt false
	o6.txt false
	o7.txt false
	EOF
	test_cmp expect actual
'

test_done
