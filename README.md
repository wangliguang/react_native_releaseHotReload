# react-native-releaseHotReload

本项是基于RN的拆包机制，建议优先研究明白[react-native-multibundler](<https://github.com/smallnew/react-native-multibundler>)



## 需求

在不重启app的情况下更新某个模块，栗子：

> 1. 首先加载基础包
> 2. 点击进入A模块之前，如果判定A模块有更新，在后台下载新A模块，加载旧的A模块
> 3. 当退出A模块再次进入A模块时删除旧A模块，加载新A模块
>
> 4. 整个流程不重启App

## 理论基石

iOS

> 1. RCTBridge中的executeSourceCode可以向初始化的bridge里面追加bundle
> 2. 通过分类的方式将RCTBridge中的executeSourceCode暴露出来
> 3. executeSourceCode碰到相同的模块ID，并不会覆盖，始终使用老版本

android

> 尚未研究

## 脚本

打基础包

```bash
# 对应脚本yarn baseBundle

node ./node_modules/react-native/local-cli/cli.js bundle --platform ios --dev false --entry-file base.js --bundle-output ./ios/base.ios.bundle --assets-dest ./ios/ --config /Users/wangliguang/Desktop/github/react_native_releaseHotReload/base.config.js
```

打更新前包

```bash
# 对应脚本yarn indexBundle

node ./node_modules/react-native/local-cli/cli.js bundle --platform ios --dev false --entry-file ggsrc/index.js --bundle-output ./ios/index.ios.bundle --assets-dest ./ios/ --config /Users/wangliguang/Desktop/github/react_native_releaseHotReload/index.config.js
```

打更新后包

```bash
# 对应脚本 yarn indexUpdateBundle

node ./node_modules/react-native/local-cli/cli.js bundle --platform ios --dev false --entry-file ggsrc/index.js --bundle-output ./ios/indexUpdate.ios.bundle --assets-dest ./ios/ --config /Users/wangliguang/Desktop/github/react_native_releaseHotReload/index.config.js
```

` yarn indexUpdateBundle`和`yarn indexBundle`的主要区别是入口文件内容和bundle名字不一样，用来模拟是更新前和更新后bundle，所以在打包后两个包之前记得修改ggsrc/App.js中内容

## 打包配置文件

因为executeSourceCode在碰到相同的模块不会覆盖，因此每次打包都需要重新指定A模块的id，所以`createModuleIdFactory` 的实现如下：

```javascript
let timestamp = new Date().getTime();
function createModuleIdFactory() {
    const projectRootPath = __dirname;
    return path => {
        //console.log('path ',path);
        let name = '';
        if(path.indexOf('node_modules'+pathSep+'react-native'+pathSep+'Libraries'+pathSep)>0){
            name = path.substr(path.lastIndexOf(pathSep)+1);
        }else if(path.indexOf(projectRootPath)==0){
            name = path.substr(projectRootPath.length+1);
        }
        name = name.replace('.js','');
        name = name.replace('.png','');
        let regExp = pathSep=='\\'?new RegExp('\\\\',"gm"):new RegExp(pathSep,"gm");
        name = name.replace(regExp,'_');//把path中的/换成下划线
        console.log(path);
        if(/ggsrc/.test(path)) {
          return name+timestamp;
        }
        return name;
    };
}
```

**说明**

> 1. 原来给的模块是不会重复32位随机值，但打包是发现同一个模块下`createModuleIdFactory`会被执行多次，这就造成同样的模块每次得到的id是不一致的，这样打包后在加载时会报红提示模块找不到，由此了解模块id需要和模块进行绑定，不能是随机值
> 2. 接着打包我使用的是react-native-multibundler库里的createModuleIdFactory实现，思路指是将路径与模块id绑定，但此时我更新A模块并加载新A模块还是使用的老版本，**因为`executeSourceCode`碰到相同的模块ID，并不会覆盖，始终使用老版本**
> 3. 在之前createModuleIdFactory实现的基础上，每次打包前我都指定一个时间戳，此次打包的所有模块id都加上一个同样的时间戳，这样就保证我加载新A模块时，指向的是更新后的代码
> 4. 如果仅仅是加时间戳还好说，但后来发现在打A模块时，A还是会包含一些基础模块的内容，比InitializeCore模块，它在每个bundle里都存在，这样就造成打多少个bundle就会有多少个InitializeCore模块，又因为每次打包指定的时间戳不一致，所以InitializeCore生成的模块id也不一样，就又产生了第一步说到的问题
> 5. 最终解决方式是只有自己写的业务代码才指定时间戳，其他不指定，还是保留原来的方式去生成模块id

## 问题

在加载新A模块后，不重启App的情况下bridge里面还是有旧A模块的内容无法清除，但这个问题不大，有如两个原因：

> 1. 只有在更新模块的时候才会出现这个问题，在两次更新某个模块过程中用户重启App的概率还是比较大的
> 2. 现在App内存都大的很，另外分包每个业务Bundle的也是较小，因此多这么点内存不会造成太大的影响

