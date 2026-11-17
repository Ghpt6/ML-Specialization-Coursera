"""Small integration checks for the course environments, without running exercises."""
import argparse
import asyncio
import importlib.metadata
import os
from pathlib import Path
import sys
import warnings


ROOT = Path(__file__).resolve().parents[1]
COURSES = {
    "1": "Course 1 - Supervised Machine Learning (Regression and Classification)",
    "2": "Course 2 - Advanced Learning Algorithms",
}


def check_notebook_kernel(course_dir, number):
    # Standalone plotting does not exercise IPython's Matplotlib integration.
    import nbformat
    from nbclient import NotebookClient

    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    code = """import matplotlib.pyplot as plt
fig, ax = plt.subplots()
ax.plot([0, 1], [0, 1])
fig.canvas.draw()
plt.close(fig)
"""
    notebook = nbformat.v4.new_notebook(cells=[
        nbformat.v4.new_code_cell("%matplotlib inline\n" + code),
        nbformat.v4.new_code_cell("%matplotlib widget\n" + code),
    ])
    NotebookClient(
        notebook,
        kernel_name=f"ml-course-{number}",
        timeout=60,
        resources={"metadata": {"path": str(course_dir)}},
    ).execute()
    print("PASS: local Jupyter kernel, inline plots and interactive widget backend")


def check_course_one(course_dir):
    # Reproduce the original notebook's widget and its actual fit callbacks.
    import matplotlib
    matplotlib.use("module://ipympl.backend_nbagg")
    import matplotlib.pyplot as plt
    import numpy as np

    lab_dir = course_dir / "Week 3" / "labs"
    os.chdir(lab_dir)
    sys.path.insert(0, str(lab_dir))
    from plt_overfit import overfit_example

    with warnings.catch_warnings():
        warnings.filterwarnings("ignore", category=FutureWarning, message="'normalize'.*")
        for regularize in (False, True):
            example = overfit_example(regularize)
            try:
                if regularize:
                    example.lambut.button.set_active(2)
                for mode in (1, 0):
                    example.typebut.button.set_active(mode)
                    for degree in range(1, 7):
                        example.degrbut.button.set_active(degree - 1)
                        assert example.degree == degree
                        assert example.logistic == (mode == 1)
                        example.fitdata_clicked(None)
                        assert np.isfinite(example.w).all()
                        assert np.isfinite(example.b).all()
            finally:
                plt.close(example.fig)
    print("PASS: original overfitting widget, both data types, degrees 1-6, with/without regularization")


def check_course_two(course_dir):
    os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
    import tensorflow as tf
    import numpy as np
    import pandas as pd
    import networkx as nx
    from xgboost import XGBClassifier

    x = np.array([[0., 0.], [0., 1.], [1., 0.], [1., 1.]], dtype=np.float32)
    y = np.array([0, 1, 1, 0])
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(2,)),
        tf.keras.layers.Dense(3, activation="relu"),
        tf.keras.layers.Dense(1, activation="sigmoid"),
    ])
    model.compile(optimizer=tf.keras.optimizers.Adam(0.01), loss="binary_crossentropy")
    loss = model.train_on_batch(x, y)
    assert np.isfinite(loss)
    classifier = XGBClassifier(n_estimators=2, max_depth=1, n_jobs=1)
    # Course 2 passes early_stopping_rounds to fit(), as supported before XGBoost 2.1.
    with warnings.catch_warnings():
        warnings.filterwarnings("ignore", category=UserWarning, message=".*early_stopping_rounds.*")
        classifier.fit(x, y, eval_set=[(x, y)], early_stopping_rounds=1, verbose=False)
    assert classifier.predict(x).shape == y.shape
    assert pd.DataFrame(x).shape == (4, 2)
    assert nx.path_graph(3).number_of_edges() == 2
    print("PASS: TensorFlow/Keras training, XGBoost fitting, pandas and networkx")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("course", choices=COURSES)
    args = parser.parse_args()
    course_dir = ROOT / COURSES[args.course]
    assert sys.version_info[:2] == (3, 11), sys.version
    assert Path(sys.prefix).resolve() == (course_dir / ".venv").resolve(), sys.prefix
    for package in ("numpy", "scipy", "scikit-learn", "matplotlib", "ipympl", "jupyterlab"):
        print(f"{package}: {importlib.metadata.version(package)}")
    check_notebook_kernel(course_dir, args.course)
    if args.course == "1":
        check_course_one(course_dir)
    else:
        check_course_two(course_dir)


if __name__ == "__main__":
    main()
