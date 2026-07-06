---
name: cozy-crt-pixelpunk
description: 用于构建具有复古 CRT 显示器拟真质感与《星露谷物语》温馨像素风（16-bit RPG）相结合的前端交互界面、看板、小游戏或控制台。
---

# Cozy-CRT Pixelpunk (温情复古 CRT 像素风) 设计规范与实现指南

本 Skill 指导 Agent 如何在前端界面设计中，将**复古电子管显像管（CRT）物理质感**与**温馨像素 RPG（Stardew-like）UI** 融合成一套高对比度、触感优异、多声道声效反馈的趣味前端组件系统。

## 1. 核心设计代币 (Design Tokens)

在构建布局与样式时，必须遵守以下视觉真值：

### 配色与对比度 (Palette & Contrast)
- **纸张底色**：容器主背景使用高亮乳白色 `#ffffff`，次级或非激活面板使用暖羊皮纸色 `#fcf2d9`。
- **木纹文字**：主文字、图标线条及主要边框统一使用深巧克力黑 `#2c1200`，确保在浅色背景下达到 AAA 级的高可读对比度。
- **高亮饰边**：主按钮、选中状态、金属包边使用明黄色 `#f3be3c`，辅以深金阴影 `#a0720a`。
- **状态属性条**：生命值（红）`#d32f2f`，体力值（绿）`#27ae60`，水分/护盾（蓝）`#2980b9`，橙色警告 `#d35400`。

### 字体排版 (Typography)
- 强制引入并使用 `'VT323', monospace` 像素字体。
- 英文标题推荐 `Press Start 2P`。
- 文本尺寸维持在 `18px - 24px` 之间，确保像素边缘在高清晰度下依然平滑可辨。

---

## 2. 拟真 CRT 物理滤镜叠加规则 (CRT Layering Rules)

所有的 CRT 显示器质感都在屏幕最顶层叠加以下 `:before`/`:after` 图层实现（必须设置 `pointer-events: none` 防止阻碍交互）：

1. **温和暗角与屏幕弧度 (Vignette & Curvature)**：
   使用浅透明径向渐变，边缘不透明度控制在 `35%` 左右，中心透明区维持在 `70%`，保留极佳的中心阅读视野。
   ```css
   background: radial-gradient(circle, transparent 70%, rgba(0, 0, 0, 0.35) 100%);
   box-shadow: inset 0 0 40px rgba(0, 0, 0, 0.6);
   ```
2. **三原色避阴栅格与扫描线 (RGB Subpixel Shadow Mask)**：
   不透明度控制在 `12%` 以下，采用水平扫描线与微观垂直红绿蓝渐变相交：
   ```css
   background: 
     linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.12) 50%),
     linear-gradient(90deg, rgba(255, 0, 0, 0.03), rgba(0, 255, 0, 0.01), rgba(0, 0, 255, 0.03));
   background-size: 100% 3px, 5px 100%;
   ```
3. **滚动光栅 (Roll Bar)**：
   使用极低不透明度的白色亮带，从上至下循环滚动。
4. **物理亮度控制 filter 映射 (Brightness Dial Filter)**：
   将外壳物理 Bright 旋钮点击事件与 CSS Filter 变动量绑定，动态切换屏幕容器滤镜：
   `filter: brightness(var(--screen-brightness)) contrast(var(--screen-contrast))`。

---

## 3. 像素风互动控件开发规范 (Interactive Controls)

- **立体触感按钮 (Tactile Buttons)**：
  必须带有 `border-bottom: 5px solid var(--stardew-wood-dark)` 的物理厚度。激活（`:active`）时下沉 `translateY(3px)` 且减小下底边厚度。
- **自定义选择框 (Checkbox & Radio)**：
  隐藏原生控件，用 CSS 绘制正方形木纹勾选框（选中呈现像素对勾 `✓`）和圆形单选钮（选中呈现实心金币圆点）。
- **NPC 气泡对话框 (Speech Balloon)**：
  容器带有绝对定位的左上角标头，内部包含一个像素风表情符号头像区和多行文本，响应其它控件触发的事件。
- **移动端轻快响应**：
  配置 `touch-action: manipulation` 和 viewport 防缩放，彻底消除 iOS Safari 上的 300ms 点击判定延迟。

---

## 4. 8-bit 声效合成参数标准 (Sound Synthesis Guide)

全部声效均在用户首次交互后，使用浏览器原生 **Web Audio API** 实时通过线性渐变（`linearRampToValueAtTime`）进行零延迟无错合成：

*   **开箱子 (`chest-open`)**：
    1. 金属锁扣 click 声：三角波，1200Hz -> 800Hz，耗时 0.03s。
    2. 木盖转动吱呀声：加速-减速的 8 次木纹敲击脉冲（延时分布在 `0.02s` 至 `0.44s`），并在中段叠加 220Hz -> 440Hz 锯齿波带通过滤铰链尖叫。
*   **关箱子 (`chest-close`)**：
    1. 合页滑动声：三角波 180Hz 瞬间淡出。
    2. 箱体合上 Thud 闷响：双层重低音融合（100Hz 正弦 + 150Hz 三角波快速滑落至 60/90Hz），峰值 Gain 为 0.18。
    3. 铜锁惯性抖动声：800Hz 高频极速衰减。
*   **普通按键音 (`click`)**：
    三角波 160Hz -> 60Hz 快速衰减，Gain 0.12，耗时 0.06s。
*   **成功与获得物品 (`success`)**：
    双音符上升，C5（0.08s）无缝衔接 E5（0.17s）。
