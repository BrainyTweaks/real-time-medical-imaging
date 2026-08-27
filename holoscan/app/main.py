
# Project 259 — Clean GPU Streaming Benchmark

import time

import cupy as cp
from holoscan.core import Application, Operator, OperatorSpec


class Project259SourceOp(Operator):
    """Produces 512x512 uint8 GPU frames at a controlled 30 FPS."""

    def __init__(self, fragment, *args, **kwargs):
        super().__init__(fragment, *args, **kwargs)

        self.frame_id = 0
        self.next_frame_time = None
        self.frame_period = 1.0 / 30.0

    def setup(self, spec: OperatorSpec):
        spec.output("out")

    def compute(self, op_input, op_output, context):
        now = time.perf_counter()

        if self.next_frame_time is None:
            self.next_frame_time = now

        sleep_time = self.next_frame_time - now

        if sleep_time > 0:
            time.sleep(sleep_time)

        self.next_frame_time += self.frame_period
        self.frame_id += 1

        # Create the frame directly on the GPU.
        frame = cp.zeros((512, 512), dtype=cp.uint8)

        op_output.emit(frame, "out")

        # Only print every 30 frames.
        if self.frame_id % 30 == 0:
            print(
                f"Project 259: source produced "
                f"{self.frame_id} frames",
                flush=True,
            )


class Project259ProcessorOp(Operator):
    """Performs a simple GPU operation on each frame."""

    def __init__(self, fragment, *args, **kwargs):
        super().__init__(fragment, *args, **kwargs)

        self.frame_count = 0

    def setup(self, spec: OperatorSpec):
        spec.input("in")
        spec.output("out")

    def compute(self, op_input, op_output, context):
        frame = op_input.receive("in")

        if frame is None:
            return

        self.frame_count += 1

        # Simple GPU processing operation.
        processed_frame = frame + cp.uint8(1)

        op_output.emit(processed_frame, "out")

        # Only print every 30 frames.
        if self.frame_count % 30 == 0:
            print(
                f"Project 259: processor processed "
                f"{self.frame_count} frames",
                flush=True,
            )


class Project259SinkOp(Operator):
    """Receives processed GPU frames and measures throughput."""

    def __init__(self, fragment, *args, **kwargs):
        super().__init__(fragment, *args, **kwargs)

        self.frame_count = 0
        self.start_time = None
        self.last_report_time = None
        self.last_report_count = 0

    def setup(self, spec: OperatorSpec):
        spec.input("in")

    def compute(self, op_input, op_output, context):
        frame = op_input.receive("in")

        if frame is None:
            return

        self.frame_count += 1

        now = time.perf_counter()

        if self.start_time is None:
            self.start_time = now
            self.last_report_time = now

        # Report every 30 frames.
        if self.frame_count % 30 == 0:
            elapsed = now - self.start_time

            interval_elapsed = now - self.last_report_time
            interval_frames = self.frame_count - self.last_report_count

            overall_fps = (
                self.frame_count / elapsed
                if elapsed > 0
                else 0.0
            )

            interval_fps = (
                interval_frames / interval_elapsed
                if interval_elapsed > 0
                else 0.0
            )

            print(
                f"Project 259: sink frames={self.frame_count} "
                f"interval_FPS={interval_fps:.2f} "
                f"overall_FPS={overall_fps:.2f} "
                f"shape={frame.shape} dtype={frame.dtype}",
                flush=True,
            )

            self.last_report_time = now
            self.last_report_count = self.frame_count


class Project259App(Application):
    """Project 259 real-time medical imaging pipeline."""

    def compose(self):
        source = Project259SourceOp(
            self,
            name="source",
        )

        processor = Project259ProcessorOp(
            self,
            name="processor",
        )

        sink = Project259SinkOp(
            self,
            name="sink",
        )

        # GPU streaming pipeline:
        #
        # Source -> Processor -> Sink
        self.add_flow(source, processor)
        self.add_flow(processor, sink)


if __name__ == "__main__":
    app = Project259App()
    app.run()
