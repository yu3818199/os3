OS/3 operating system source code .

img/ 
 fdisk.img     #编译打包的磁盘镜像文件，可导入U盘启动系统 
src/ 
 mbr.asm   #主引导程序 
 boot.asm  #主控程序 
tools/ 
 bmptotxt.cpp  #将图片转换为文本 
 dd.cpp        #将文件写入覆盖另一个文件的指定位置 
 rwdisk.cpp    #物理方式读写U盘 
 
