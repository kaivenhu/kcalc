#!/usr/bin/env bash

CALC_DEV=/dev/calc
CALC_MOD=calc.ko
LIVEPATCH_CALC_MOD=livepatch-calc.ko

source scripts/eval.sh

test_op() {
    local expression=$1 
    local ans=${2}
    echo "Testing " ${expression} "..."
    echo -ne ${expression}'\0' > $CALC_DEV

    if [ -z ${ans} ]
    then
        ans=${expression}
    fi

    fromfixed $(cat $CALC_DEV) ${ans}
}

if [ "$EUID" -eq 0 ]
  then echo "Don't run this script as root"
  exit
fi

sudo rmmod -f livepatch-calc 2>/dev/null
sudo rmmod -f calc 2>/dev/null
sleep 1

modinfo $CALC_MOD || exit 1
sudo insmod $CALC_MOD
sudo chmod 0666 $CALC_DEV
echo

# multiply
test_op '6*7'

# add
test_op '1980+1'

test_op '134217726+1'
test_op '1.34217726+0.00000001'
test_op '1+134217726'
test_op '0.00000001+1.34217726'

test_op '134217727+1'   'OVERFLOW'
test_op '1.34217727+0.00000001'   'OVERFLOW'
test_op '1+134217727'   'OVERFLOW'
test_op '0.00000001+1.34217727'   'OVERFLOW'

test_op '(-134217727)+(-1)'
test_op '(-1.34217727)+(-0.00000001)'
test_op '(-1)+(-134217727)'
test_op '(-0.00000001)+(-1.34217727)'

test_op '(-134217728)+(-1)'   'OVERFLOW'
test_op '(-1.34217728)+(-0.00000001)'   'OVERFLOW'
test_op '(-1)+(-134217728)'   'OVERFLOW'
test_op '(-0.00000001)+(-1.34217728)'   'OVERFLOW'

test_op '(-134217728)+(134217727)'
test_op '(134217727)+(-134217727)'
test_op '(1)+(-134217728)'
test_op '(134217727)+(-1)'
test_op '(0)+(-134217728)'
test_op '(134217727)+(0)'

# sub
test_op '2019-1'
test_op '-134217727-1'
test_op '-1.34217727-0.00000001'
test_op '-1-134217727'
test_op '-0.00000001-1.34217727'
test_op '1-(-134217726)'
test_op '0.00000001-(-1.34217726)'
test_op '134217726-(-1)'
test_op '1.34217726-(-0.00000001)'
test_op '-134217728-1'  'OVERFLOW'
test_op '-1.34217728-0.00000001'  'OVERFLOW'
test_op '1-(-134217727)' 'OVERFLOW'
test_op '0.00000001-(-1.34217727)' 'OVERFLOW'
test_op '134217727-(-1)' 'OVERFLOW'
test_op '1.34217727-(-0.00000001)' 'OVERFLOW'

# div
test_op '42/6'
test_op '1/21'
test_op '1/300'
test_op '-1/300'
test_op '1/-300'
test_op '-1/-300'
test_op '1/300000'
test_op '1/0.00000003' '33333330'
test_op '10000000/0.00000003' 'OVERFLOW'
test_op '134217727/0.00000003' 'OVERFLOW'
test_op '134217727/0.0000003' '447392420000000'
test_op '-134217727/0.0000003' '-447392420000000'
test_op '1/3'
test_op '1/3*6+2/4'
test_op '(1/3)+(2/3)'
test_op '(2145%31)+23' '29'
test_op '0/0' 'NAN_INT' # should be NAN_INT

# binary
test_op '(3%0)|0' '0' # should be 0
test_op '1+2<<3' '24' # should be (1 + 2) << 3 = 24
test_op '123&42' '42' # should be 42
test_op '123^42' '81' # should be 81

# parens
test_op '(((3)))*(1+(2))' # should be 9

# assign
test_op 'x=5, x=(x!=0)' '1' # should be 1
test_op 'x=5, x = x+1' '6' # should be 6

# fancy variable name
test_op 'six=6, seven=7, six*seven' '42' # should be 42
test_op '小熊=6, 維尼=7, 小熊*維尼' '42' # should be 42
test_op 'τ=1.618, 3*τ' '4.854' # should be 3 * 1.618 = 4.854
test_op '$(τ, 1.618), 3*τ()' '4.854' # shold be 3 * 1.618 = 4.854

# functions
test_op '$(zero), zero()' '0' # should be 0
test_op '$(one, 1), one()+one(1)+one(1, 2, 4)' '3' # should be 3
test_op '$(number, 1), $(number, 2+3), number()' '5' # should be 5

# pre-defined function
test_op 'nop()' '-0.1'
test_op 'fib(10+3*10)' '0'

# Livepatch
sudo insmod $LIVEPATCH_CALC_MOD
sleep 1
echo "livepatch was applied"
test_op 'nop()' '0'
test_op 'fib(10+3*10)' '102334155'
test_op 'fib(10+3*10+1)' '0'
dmesg | tail -n 6
echo "Disabling livepatch..."
sudo sh -c "echo 0 > /sys/kernel/livepatch/livepatch_calc/enabled"
sleep 5
sudo rmmod livepatch-calc
sudo rmmod calc

# epilogue
echo "Complete"
