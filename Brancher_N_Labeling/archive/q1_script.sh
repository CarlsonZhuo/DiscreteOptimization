for (( i=10; i<=200; i=i+10 ))
do
   ./examples/langford-number -search 2 $i
done

for (( i=10; i<=200; i=i+10 ))
do
   ./examples/langford-number -search 1 $i
done