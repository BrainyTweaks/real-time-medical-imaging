from holoscan.core import Application, Operator, OperatorSpec


class SourceOperator(Operator):
    def __init__(self, fragment, *args, **kwargs):
        super().__init__(fragment, *args, **kwargs)
        self.frame_id = 0

    def setup(self, spec: OperatorSpec):
        spec.output("out")

    def compute(self, op_input, op_output, context):
        self.frame_id += 1

        frame = {
            "frame_id": self.frame_id,
            "source": "project259",
            "payload": "synthetic-frame",
        }

        print(f"Project 259: source produced frame {frame['frame_id']}.")
        op_output.emit(frame, "out")


class SinkOperator(Operator):
    def __init__(self, fragment, *args, **kwargs):
        super().__init__(fragment, *args, **kwargs)

    def setup(self, spec: OperatorSpec):
        spec.input("in")

    def compute(self, op_input, op_output, context):
        frame = op_input.receive("in")

        print(
            f"Project 259: sink received frame "
            f"{frame['frame_id']} from {frame['source']}."
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