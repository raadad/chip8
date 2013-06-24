fs = require('fs');
array1 = fs.readFileSync('orig.out').toString().split("\n");
array2 = fs.readFileSync('lol.out').toString().split("\n");

cnt = 0
for i in array1
	if array1[cnt] != array2[cnt]
		console.log cnt
		system.exit
	cnt++
	