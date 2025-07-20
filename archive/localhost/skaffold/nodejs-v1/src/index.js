const express = require('express')
const app = express()
const port = process.env.PORT || 3000

app.get('/', (req, res) => {
  res.json({ message: 'Hello from K3d!!!' })
})

app.listen(port, () => {
  console.log(`App running on port ${port}`)
})