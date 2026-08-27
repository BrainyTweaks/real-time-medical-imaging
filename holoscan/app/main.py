# Project 259 — Controlled NumPy Frame Pipeline

import time

import numpy as np

from holoscan.core import Application, Operator, OperatorSpec


class SourceOperator(Operator):
    def __init__(self, fragment, *args, **kwargs):
        super().__init__(fragment, *args, **kwargs)
        self.frame_id = 0
        self.last_frame_time = time.perf_counter()
        self.frame_interval = 1.0 / 30.0  # 30 FPS

    def setup(self, spec: OperatorSpec):
        spec.output("out")

    def compute(self, op_input, op_output, context):
        now = time.perf_counter()
        elapsed = now - self.last_frame_time

        if elapsed < self.frame_interval:
            time.sleep(self.frame_interval - elapsed)

        self.last_frame_time = time.perf_counter()

        self.frame_id += 1

        image = np.zeros((512, 512), dtype=np.uint8)

        frame = {
            "frame_id": self.frame_id,
            "source": "project259",
            "payload": image,
        }

        print(
            f"Project 259: source produced frame "
            f"{frame['frame_id']} "
            f"shape={image.shape} "
            f"dtype={image.dtype}."
        )

        op_output.emit(frame, "out")


class SinkOperator(Operator):
    def __init__(self, fragment, *args, **kwargs):
        super().__init__(fragment, *args, **kwargs)

    def setup(self, spec: OperatorSpec):
        spec.input("in")

    def compute(self, op_input, op_output, context):
        frame = op_input.receive("in")
        image = frame["payload"]

        print(
            f"Project 259: sink received frame "
            f"{frame['frame_id']} "
            f"shape={image.shape} "
            f"dtype={image.dtype} "
            f"from {frame['source']}."
        )


class Project259Application(Application):
    def compose(self):
        source = SourceOperator(self, name="source")
        sink = SinkOperator(self, name="sink")

        self.add_operator(source)
        self.add_operator(sink)

        self.add_flow(source, sink, {("out", "in")})


if __name__ == "__main__":
    app = Project259Application()
    app.run()