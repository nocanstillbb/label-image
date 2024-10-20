# 注意

由于本项目嵌入GPL许可证的的终端程序,[Swordfish90/cool-retro-term](https://github.com/Swordfish90/cool-retro-term) 

所以本项目也仅支持GPL许可证, 并且由于此依赖只支持mac os和linux, 所以本项目**不打算直接支持windows**  

但如果对在windows上运行程序感兴趣,可以参考我[这篇博客](https://nocanstillbb.github.io/post/windows_wsl2_nvidia-docker2%E9%95%9C%E5%83%8F%E8%AE%B0%E5%BD%95/),使用wsl2 + nvidia docker 2 runtime 在docker中使用cuda加速训练 


如果需要在windows上使用此程序,可以考虑 `Nvidia docker2`  + ubuntu的docker 

若是在macOs下构建,需要使用13.3或以下版本的MacosX sdk,否则将会构建失败


```cmake
set(CMAKE_OSX_SYSROOT /Library/Developer/CommandLineTools/SDKs/MacOSX13.3.sdk)
```


# 一些快照

<img width="1681" alt="image" src="https://github.com/user-attachments/assets/8f284122-15e9-40ef-8662-aa7fded1265e">  
  
<img width="1347" alt="image" src="https://github.com/user-attachments/assets/8c34d333-5700-4ea7-86a7-a77b06b91f90">

  





