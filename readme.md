# 运行

80386汇编语言、Irvine32库、Visual Studio 2019

【自行搜索在VS配置Irvine32库】

# 代码结构

main程序

1. `readMatrix PROC`：读文件到缓冲区buffer
2. `loadMatrix`：将缓冲区字符串解析为矩阵，存储到数组中
3. `calOneRow PROC USES ecx`：计算矩阵1的一行分别乘B矩阵的每一列
4. `calRows PROC`：对矩阵1的每一行调用`calOneRow`
5. `writeMatrix PROC`：

# 步骤

1. 输入矩阵A文件名，输入矩阵B文件名，输入矩阵C文件名

2. 读取矩阵A和矩阵B到缓冲区，然后将缓冲区字符串解析为矩阵，存储到数组中。

3. 判断矩阵A的列是否和矩阵B的行相同，不相同输出不满足条件，相同向下计算。

4. `calOneRow`函数Loop循环遍历矩阵A的行

5. `calRows PROC`函数外层循环遍历矩阵B的每一列，内层循环遍历矩阵A的一行。内部循环遍历矩阵A的行，计算矩阵A乘以矩阵B数字，累加求和，存入矩阵C中。

   外部循环遍历矩阵B的列，重复上一步骤。

6. 将矩阵C输出并保存到文件。

# 注意

文件1.txt和文件2.txt输入矩阵时，最后要有一个回车换行



# 











