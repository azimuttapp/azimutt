export const rootHtml = (json: Record<string, any>) => `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azimutt</title>
</head>
<body>
    <div id="root"></div>
    <script crossorigin src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script type="text/javascript" src="https://unpkg.com/babel-standalone@6/babel.js"></script>
    <script type="text/javascript">
        const report = ${JSON.stringify(json)}
    </script>
    <script type="text/babel">
        function App() {
            return <h1>Hello</h1>;
        }
        ReactDOM.render(
            <App />,
            document.getElementById("root")
        );
    </script>
</body>
</html>
`