//
//  ContentHtmlParserTest.swift
//  ecnu.imTests
//
//  Created by 陈俊杰 on 2022/3/27.
//

import XCTest

class ContentHtmlParserTest: XCTestCase {

    func testExample() throws {
        let parser = ContentHtmlParser()
        let html = """
<h1>0.1.0</h1>
\n
<p>发布于 2022-03-16</p>
\n
<h2>功能优化</h2>
\n\n
<ul>
  <li>论坛现在拥有正式域名并支持 HTTPS 了</li>
  \n
  <li>新增 「Emoji 选择框」：可以在编辑器右下角选择并使用 Emoji</li>
  \n
  <li>左侧边栏新增「论坛统计」</li>
  \n
  <li>网站右上角新增「日间/夜间模式切换」功能</li>
  \n
  <li>完善「个人资料」：可以编辑用户个性签名啦</li>
  \n
  <li>在主题/回复的右下角可以「戳表情」进行互动</li>
  \n
  <li>现在注册时需要隐形 reCAPTCHA</li>
  \n
  <li>导航栏添加了若干链接</li>
  \n
  <li>新增「发布私密主题」功能，可指定对哪些用户/用户组可见</li>
</ul>
\n\n
<h2>Bug 修复</h2>
\n
<ul>
  <li>修复了回复用户时的链接指向错误 URL 的问题</li>
  \n
  <li>修复了头像上传成功后无法显示的问题</li>
</ul>
\n\n
<h2>贡献者名单</h2>
\n\n
<h4>维护者</h4>
\n
<ul>
  <li>
    <a href="https://ecnu.im/u/admin" class="UserMention">@Adm1n</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/BillChen2k" class="UserMention">@Bill Chen</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/jjaychen" class="UserMention">@jjaychen</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/elsie" class="UserMention">@Panini</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/Emandia" class="UserMention">@伊曼蒂</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/Pachacuti" class="UserMention">@Tlahuizcalli</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/superviser" class="UserMention">@Master</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/cubercsl" class="UserMention">@cubercsl</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/zongzi_00" class="UserMention">@粽子呀</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/tianyilt" class="UserMention">@tianyilt</a>
  </li>
</ul>
\n\n
<h4>开发者</h4>
\n
<ul>
  <li>
    <a href="https://ecnu.im/u/admin" class="UserMention">@Adm1n</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/BillChen2k" class="UserMention">@Bill Chen</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/jjaychen" class="UserMention">@jjaychen</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/jacklight" class="UserMention">@jacklight</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/oceanlvr" class="UserMention">@oceanlvr</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/cubercsl" class="UserMention">@cubercsl</a>
  </li>
  \n
  <li>
    <a href="https://ecnu.im/u/tianyilt" class="UserMention">@tianyilt</a>
  </li>
</ul>
\n\n
<h2>加入我们</h2>
\n
<p>
  欢迎有意向参与维护的同学加入维护讨论组：
  <a href="https://discord.gg/a9NBjHwBEQ" rel=" nofollow ugc">https://discord.gg/a9NBjHwBEQ</a>
</p>
\n\n
<p>
  在
  <a href="https://github.com/ECNU-Forum/ECNU-Forum" rel=" nofollow ugc">这里</a>
  记录了一系列尚待解决的问题，欢迎大家来解决这些问题成为论坛的贡献者。
</p>
\n\n
<p>最后，感谢大家的转发和支持~</p>
"""
        parser.parse(html)
    }


}
