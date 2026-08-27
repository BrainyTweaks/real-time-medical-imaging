from holoscan.core import Application, Operator, OperatorSpec


class SourceOperator(Operator):
    def __init__(self, fragment, *args, **kwargs):
        super().__init__(fragment, *args, **kwargs)

    def setup(self, spec: OperatorSpec):
        spec.output("out")

    def compute(self, op_input, op_output, context):
        print("Project 259: Holoscan source operator executed.")
        op_output.emit("frame", "out")


class SinkOperator(Operator):
    def __init__(self, fragment, *args, **kwargs):
        super().__init__(fragment, *args, **kwargs)

    def setup(self, spec: OperatorSpec):
        spec.input("in")

    def compute(self, op_input, op_output, context):
        message = op_input.receive("in")
        print(f"Project 259: Holoscan sink received: {message}")


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