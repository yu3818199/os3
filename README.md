OS/3 operating system source code . <br>
<br>
written by yuqiancheng @2019 <br>
<br>
img/ <br>
hdisk.img     #编译打包的磁盘镜像文件，可导入U盘启动系统 <br>
<br>
src/ <br>
mbr.asm   #主引导程序 <br>
boot.asm  #主控程序，展示主界面，实现操作系统关机、重启，扩展程序加载等功能。 <br>
dec.asm  #数值转换，2进制转10进制，2进制转16进制等功能 <br>
disk.asm #磁盘管理，磁盘信息读取，读写磁盘等功能 <br>
memory.asm #内存管理，内存更新、复制、比较等功能  <br>
screen.asm #屏幕控制，清屏，打印字符等功能 <br>
FileAllocationTable.asm #文件分区表 <br>
app_screen.asm #本操作系统的第一个应用程序 <br>
<br>
tools/ <br>
bmptotxt.cpp  #将图片转换为文本 <br>
dd.cpp        #将文件写入覆盖另一个文件的指定位置，用于编绎后生成二进制执行文件 <br>
rwdisk.cpp    #物理方式读写U盘，用于将执行文件写入U盘 <br>
 
