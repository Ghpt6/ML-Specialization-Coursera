# Coursera 机器学习专项课程 (中文翻译版)
特别感谢吴恩达（Andrew Ng）及 Coursera 团队的其他成员，为大家打造了这套通俗易懂的机器学习入门专项课程。本仓库收录了课程提供的编程作业（未解答版本）、测验和探索性实验。

## 如何完成练习
这些练习通常使用交互式 Python 笔记本（即 `.ipynb` 文件）。你可以使用 [Google Colaboratory](https://colab.research.google.com/)、[Deepnote](deepnote.com) 或 [Jupyter Notebook](https://jupyter.org/) 等工具来完成练习。

欢迎 Fork 本仓库，供个人学习使用。如果发现内容缺失，欢迎在 GitHub 上提交 Issue。祝学习愉快 :)

## 本地一键安装（Windows x64）

课程 1、课程 2 各自使用课程目录下的 `.venv`，依赖互不混用。课程 3 暂未配置环境。
首次安装需要联网访问 GitHub 和 PyPI；不需要预装 Python、uv 或 Anaconda，也不需要管理员权限。

克隆后，在仓库根目录双击 `setup.cmd`，即可安装课程 1 和课程 2。也可以在 PowerShell 中按需安装：

```powershell
.\setup.cmd 1       # 仅安装课程 1
.\setup.cmd 2       # 仅安装课程 2
.\setup.cmd all     # 安装两个独立环境（默认）
```

安装器下载固定版本的 uv，并校验下载文件的 SHA256；将 Python 3.11.15、下载缓存和辅助文件放入根目录的 `.tools`。
每门课程的 `pyproject.toml` 指定直接依赖，`uv.lock` 固定全部依赖版本及下载哈希，`.python-version` 固定 Python 版本。
环境及工具目录均已被 Git 忽略；其他人克隆配置文件后会在自己的项目目录中重建环境。
Python 不会注册到系统或加入系统 PATH，Jupyter 内核也仅安装到相应课程的 `.venv`。

| 环境 | Python | 主要依赖 |
| --- | --- | --- |
| 课程 1 | 3.11.15 | NumPy 1.26.4、SciPy 1.10.1、scikit-learn 1.1.3、Matplotlib 3.7.5 |
| 课程 2 | 3.11.15 | 上述基础库，以及 TensorFlow 2.15.1 / Keras 2、pandas 1.5.3、XGBoost 2.0.3、NetworkX 3.2.1 |

两个环境均包含 JupyterLab、ipykernel、ipywidgets 和 ipympl，并固定 IPython 8.37.0 与 matplotlib-inline 0.1.7，以兼容旧 Matplotlib 的 notebook 绘图接口。
课程 2 的 TensorFlow 下载较大，Windows 下使用 CPU；安装包名为 `tensorflow-intel`，课程中的 `import tensorflow` 保持原样。
固定旧版 scikit-learn 是为了兼容课程原代码中的 `penalty='none'` 和 `normalize=True`；后者可能显示弃用警告，不是运行错误。

### 启动实验

```powershell
.\start-lab.cmd 1   # 使用课程 1 环境打开 JupyterLab
.\start-lab.cmd 2   # 使用课程 2 环境打开 JupyterLab
```

现有的课程 1、2 notebook 已分别将默认内核设为 `ml-course-1` 和 `ml-course-2`，显示名称为 `ML Course 1 (Python 3.11)` 和 `ML Course 2 (Python 3.11)`，目标 Python 版本为 3.11.15。
安装后从对应课程的 JupyterLab 打开 notebook，会按文件中的内核名匹配该课程环境；这些元数据不包含个人电脑的绝对路径或解释器哈希。
内核从 notebook 所在目录启动，因此课程代码中的 `./deeplearning.mplstyle` 和相对数据路径可以正常解析。

VS Code 用户可打开根目录的 `ML-Specialization.code-workspace`，安装推荐的 Python 和 Jupyter 扩展，也可以单独打开某一门课程的目录。
每个课程目录的 `.vscode/settings.json` 将默认 Python 解释器设为该目录内的 `.venv`。
VS Code 会优先记住 notebook 上次使用的内核；若以前打开过该文件且仍选中 Python 3.14，在“选择内核”中切换到所属课程的 `.venv\Scripts\python.exe` 一次，再从头运行。
这是编辑器的本地选择记录，详见 [VS Code 内核选择说明](https://code.visualstudio.com/docs/datascience/jupyter-kernel-management)。
仅切换终端中的 Python 不会自动切换已运行的 notebook 内核。

如果切换内核后 notebook 的 `language_info.version` 出现 `3.11.-1`，这是编辑器未识别到补丁版本号，并非实际安装了这个版本。
安装器会在同步依赖后，根据实际解释器补全 `.venv/pyvenv.cfg` 中的 `version` 和 `version_info`，避免 uv 仅记录 `3.11` 时触发此问题。
已有环境可重新运行对应课程的安装命令修复；随后在 VS Code 命令面板执行 `Python: Refresh All Environment Managers`，重新选择课程内核。若仍显示缓存版本，再执行 `Developer: Reload Window`。

### 检查与维护

安装结束会自动运行依赖检查，以及真实 Jupyter 内核中的静态图和交互图检查。课程 1 还检查原始 overfitting 交互图的两种模式、1–6 次多项式和正则化；课程 2 检查 TensorFlow/Keras 与 XGBoost 的实际拟合。
这些检查不执行或填写编程作业，也不修改课程源文件。

脚本可重复执行。执行前请关闭正在使用对应 `.venv` 的 notebook 内核及 JupyterLab；同步会恢复锁定的依赖版本，并移除该环境中不在锁定文件里的额外包。
如果下载中断，保持网络可用后再次运行。若已有 `.venv` 使用其他 Python 版本，脚本会停止并提示先重命名旧目录。
自动化执行可直接运行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1 1`，避免 `.cmd` 末尾的按键等待。

需要更改依赖时，编辑对应课程的 `pyproject.toml`，然后使用项目自带的 `.tools\uv-0.11.24\uv.exe lock --project "课程目录"` 更新锁定文件，再重新运行安装器验证。
提交 `pyproject.toml`、`uv.lock`、`.python-version` 和根目录的脚本、工作区配置及说明，即可让其他克隆用户复现环境。
移动项目目录后应重建 `.venv`，不要直接复制已安装的虚拟环境。

## 附注
如果你想获取深度学习课程的未解答练习，请查看[这个仓库](https://github.com/karkir0003/Deep-Learning-Specialization-Coursera/tree/main)。
