# hjexe
hijack executable file

``` shell 
make install
hjexe
```

# 设计
```  
1.  cmdx
    [cmdx]    
     |          
     +-> hjexe -> cmdx.raw

2.  [cmd1] -> cmdx
    [cmd1]     
      |       
      +-> hjexe -> cmdx.raw

3.  cmd1 -> cmd2 -> cmd3 -> cmdx
    [cmd1]    [cmd2] -> [cmd3] -> cmd
      |       
      +-> hjexe.sh -> cmdx.raw
```
