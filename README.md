# jc_overlay

用于存放自定义或测试中的软件包。

## 如何使用此 Overlay

```bash
doas emerge app-eselect/eselect-repository

doas eselect repository add jc_overlay git https://github.com/jczhang02/jc_overlay.git

doas emerge --sync jc_overlay
```
