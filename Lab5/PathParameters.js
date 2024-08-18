export default function PathParameters(app) {
    app.get("/lab5/add/:a/:b", (req, res) => {
        const { a, b } = req.params;
        const sum = parseInt(a) + parseInt(b);
        res.send(sum.toString());
    });
    app.get("/lab5/subtract/:a/:b", (req, res) => {
        const { a, b } = req.params;
        const sum = parseInt(a) - parseInt(b);
        res.send(sum.toString());
    });
    app.get("/lab5/multiply/:a/:b", (req, res) => {
        const { a, b } = req.params;
        const prod = parseInt(a) * parseInt(b);
        res.send(prod.toString());
    });
    app.get("/lab5/divide/:a/:b", (req, res) => {
        const { a, b } = req.params;
        if (parseInt(b) === 0)
            res.send(
        `<html><head><script>
			window.location.replace("https://youtu.be/8HqyEHqEYho");
		</script></head></html>))`);
        const joy = parseInt(a) / parseInt(b);
        res.send(joy.toString());
    });
    // had to include a music easter egg for my own :)
};
