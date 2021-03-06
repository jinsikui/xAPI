# <a name="top"></a>xAPI

* [概述](#概述)
* [安装](#安装)
* [Demo](#demo)
* [使用](#使用)
   * [Objc](#objc)
   * [Swift](#swift)
   * [自适应服务端返回数据结构](#adaptret)
* [公共参数](#公共参数)
   * [commonParams](#commonparams)
   * [commonHeaders](#commonheaders)
   * [区分不同子系统](#tags)

## 概述

业务无关的链式API调用工具，支持 objc / swift

底层网络访问基于 [AFNetworking](https://github.com/AFNetworking/AFNetworking)

异步返回处理基于google的 [promise](https://github.com/google/promises)

## 安装

通过pod引用，在podfile增加下面一行，通过tag指定版本
```
pod 'xAPI',         :git => "https://github.com/jinsikui/xAPI.git", :tag => 'vX.X.X-X'
```
 objc代码中引入：
```
#import <xAPI/xAPI.h>
```
 swift代码中引入：
```
在项目的plist文件中配置置 'Objective-C Bridging Header = xxx.h'，在xxx.h中添加一行：
#import <xAPI/xAPI.h>
```

## <a name="demo"></a> Demo

直接下载本工程运行即可启动demo

## 使用

### <a name="objc"></a> - Objc 

```objc
xAPI.host(@"https://xxx.com")
   .method(HTTP_GET)
   .path([NSString stringWithFormat:@"/v1/%lu/users", (unsigned long)roomId])
   .execute().then(^id(NSDictionary *ret){
      // process api ret in main thread
      NSArray *users = ret[@"users"];
      // do business logic ...
      return nil;
   }).catch(^(NSError *error){
      // 错误处理
      NSInteger code = error.code;
      NSString *errorMsg = error.userInfo[xAPIErrorMessageKey]; //errorMsg could be @""
      // do with error info ...
   });

```
### <a name="swift"></a> - Swift

```swift
xAPI.host("https://xxx.com").method(xHTTPMethod.HTTP_GET)
   .path("/v1/\(roomId)/users")
   .execute().__onQueue(DispatchQueue.main, then:{ ret in
        // process api ret in main thread
        // 这里提取数据的类型转换有点繁琐，推荐用 SwiftyJSON 等三方库来处理json对象
        let dic = ret as! [String : AnyObject]
        let users = dic["users"] as! Array<[String : AnyObject]>
        // do business logic ...
        return nil
   }).__onQueue(DispatchQueue.main, catch:{ error in
        // 错误处理
        let error = error as NSError
        let code = error.code
        let errorMsg = error.userInfo[xAPIErrorMessageKey] //errorMsg could be ""
        // do with error info ...
   })
```

### <a name="adaptret"></a> - 自适应服务端返回数据结构

```objc
// xAPI会对服务端返回的原始数据中的"data","error code","error message"三部分信息进行提取，并且对这几部分兼容不同的key，以适配不同的服务端团队
// xAPI内部代码：
    NSInteger errorCode = 0;
    NSString *errorMsg = nil;
    if (response.statusCode != 200) {
        errorCode = response.statusCode > 0 ? response.statusCode : 110; /*110代表请求超时*/
    }
    if ([response.responseObject isKindOfClass:NSDictionary.class]) {
        NSDictionary *body = response.responseObject;
        if (xapi_not_null(body[@"errcode"]) || xapi_not_null(body[@"code"]) || xapi_not_null(body[@"errorno"]) || xapi_not_null(body[@"errCode"])) {
            //code not null
            NSInteger code = xapi_not_null(body[@"errcode"]) ? [body[@"errcode"] integerValue] : xapi_not_null(body[@"code"]) ? [body[@"code"] integerValue] : xapi_not_null(body[@"errorno"]) ?  [body[@"errorno"] integerValue] : [body[@"errCode"] integerValue];
            if (code != 200 && code != 0) {
                errorCode = code;
            }
        }
        errorMsg = xapi_not_null(body[@"errmsg"]) ? body[@"errmsg"] : xapi_not_null(body[@"msg"]) ? body[@"msg"] : xapi_not_null(body[@"errormsg"]) ? body[@"errormsg"] : xapi_not_null(body[@"errMsg"]) ? body[@"errMsg"] : nil;
    }
    if (errorCode > 0) {
        if (completion) {
            completion(response, errorCode, errorMsg);
        }
        return;
    }

    if([response.responseObject isKindOfClass:NSDictionary.class]){
        NSDictionary *body = response.responseObject;
        id data = xapi_not_null(body[@"data"]) ? body[@"data"] : xapi_not_null(body[@"ret"]) ? body[@"ret"] : nil;
        if (data != nil) {
            response = [[xNetworkResponse alloc] initWithResponse:response adpatedObject:data];
        }
    }
    if (completion) {
        completion(response, errorCode, errorMsg);
    }
   // ......
```
## 公共参数

```
对于所有api请求都附带的公共参数，不必每次调用都写一次，xAPI可以配置几个全局的回调(blocks)，在每次发起api请求时都会主动去调用，来获取公共的参数
公共参数包括 commonParams 和 commonHeaders
```

### <a name="commonparams"></a> - commonParams 

```objc
/******************************************************************************************************************************
注意：
1. xAPI.commonParams(...)是一个全局的配置，只需要在app启动时配置一次

2. xAPI.commonParams(...)配置的是一个返回字典的block，而不是字典本身，每次请求api前，这个block都会被调用，用来实时生成公共参数字典

3. 每次api调用都可以链式的指定一个commonParamsUsage，它有两个取值：
   xAPICommonParamsUsagePath：公共参数应用到api请求的querystring中，不论请求用的是不是GET方法都会添加至querystring
   xAPICommonParamsUsageParams：公共参数和api的params合并，不指定encodingType时对于GET请求添加到querystring中，否则添加到请求body的json中
   
4. commonParamUsage不是全局的，而是跟每个api绑定的，默认值为 xAPICommonParamsUsagePath
*******************************************************************************************************************************/

// app启动时配置
xAPI.commonParams(^NSDictionary * _Nonnull(NSString * _Nullable tag) {
   return [System1API commonParams];
});

// 一次具体的api调用
xAPI.host(@"https://xxx.com")
   .path(@"/test")
   .params(@{"p1": p1, @"p2": p2})
   .commonParamUsage(xAPICommonParamsUsageParams) //指定公共参数和params合并
   .method(HTTP_POST)
   .execute()
```
### <a name="commonheaders"></a> - commonHeaders

```objc
/******************************************************************************************************************************
注意：
1. xAPI.commonHeaders(...)是一个全局的配置，只需要在app启动时配置一次

2. xAPI.commonHeaders(...)配置的是一个返回字典的block，而不是字典本身，每次请求api前，这个block都会被调用，用来实时生成公共headers字典

3. 每次api调用也可以通过xAPI.headers(...)指定和这次api请求绑定的headers，会和commonHeaders返回的字典合并
*******************************************************************************************************************************/

// app启动时配置
xAPI.commonHeaders(^NSDictionary * _Nonnull(NSString * _Nullable tag) {
   return [System1API commonHeaders];
});

// 一次具体的api调用
xAPI.host(@"https://xxx.com")
   .path(@"/auth")
   .headers(@{"SECRET": secret}) // 本次请求绑定的headers
   .method(HTTP_GET)
   .execute()
```

### <a name="tags"></a> - 区分不同子系统

```
如上所述，xAPI.commonParams(...) 和 xAPI.commonHeaders(...) 都是全局的配置，都只能配置一个，如果不同的子系统要求的公共参数不一样怎么办呢？
这可以通过tag来解决，每次具体的api请求都可以链式的指定一个tag，这个tag会作为参数传给 xAPI.commonParams(...) 和 xAPI.commonHeaders(...)配置的block：
```
```objc

// in file AppDelegate.m ...
// ......

// 全局的公共params
xAPI.commonParams(^NSDictionary * _Nonnull(NSString * _Nullable tag) {
   if([tag isEqualToString:System1API.tag]){
      // 子系统1
      return [System1API commonParams];
   }
   else if([tag isEqualToString:System2API.tag]){
      // 子系统2
      return [System2API commonParams];
   }
   else {
      // 其他子系统
      return @{};
   }
});

// 全局的公共headers
xAPI.commonHeaders(^NSDictionary * _Nonnull(NSString * _Nullable tag) {
   if([tag isEqualToString:System1API.tag]){
      // 子系统1
      return [System1API commonHeaders];
   }
   else if([tag isEqualToString:System2API.tag]){
      // 子系统2
      return [System2API commonHeaders];
   }
   else {
      // 其他子系统
      return @{};
   }
});


// ......
// in file System1API.m（子系统1的所有API都放在这里）

/// 子系统公共逻辑
-(xAPIBuilder*)builder{
    return xAPI.tag(System1API.tag).host(System1API.host);
}

/// 某个具体的API接口
-(FBLPromise<NSDictionary*>*)getUsersInRoom:(NSString *)roomId {
    return self.builder.method(HTTP_GET).path([NSString stringWithFormat:@"/v1/%@/users", roomId]).execute();
}


// ......
// in file System2API.m（子系统2的所有API都放在这里）

/// 子系统公共逻辑
-(xAPIBuilder*)builder{
    return xAPI.tag(System2API.tag).host(System2API.host);
}

/// 某个具体的API接口
-(FBLPromise<NSDictionary*>*)getAudiencesInRoom:(NSUInteger)roomId{
    return self.builder.method(HTTP_GET).path([NSString stringWithFormat:@"/v1/%lu/audiences", (unsigned long)roomId]).execute();
}

```


