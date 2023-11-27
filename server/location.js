const express = require('express');
const mongoose = require('mongoose');

const app = express();
const port = 3000; 
mongoose.connect('mongodb://localhost:27017/dbname', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const vehicleSchema = new mongoose.Schema({
    vehicleId: { type: String, required: true, unique: true },
    lon: { type: Number, required: true },
    lat: { type: Number, required: true },
    title: { type: String },
    content: { type: String },
    loc: {
      type: { type: String },
      coordinates: [Number],
    },
  });
const Vehicle = mongoose.model('Vehicle', vehicleSchema);

app.use(express.json());

app.post('/update', async (req, res) => {
  try {
    const { vehicleId, lon, lat, title, content } = req.body;

    let vehicle = await Vehicle.findOne({ vehicleId });

    if (!vehicle) {
        vehicle = new Vehicle({
          vehicleId,
          lon,
          lat,
          title,
          content,
          loc: {
            type: 'Point',
            coordinates: [lon, lat],
          },
        });
      } else {
        vehicle.lon = lon;
        vehicle.lat = lat;
        vehicle.title = title;
        vehicle.content = content;
        vehicle.loc = {
          type: 'Point',
          coordinates: [lon, lat],
        };
      }

    await vehicle.save();

    res.status(200).json({ message: 'Update successful' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.delete('/remove', async (req, res) => {
  try {
    const { vehicleId } = req.body;

    await Vehicle.findOneAndRemove({ vehicleId });

    res.status(200).json({ message: 'Remove successful' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.get('/nearby', async (req, res) => {
  try {
    const { lon, lat } = req.query;

    const nearbyVehicles = await Vehicle.find({
      loc: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lon), parseFloat(lat)],
          },
          $maxDistance: 1000, 
        },
      },
    });

    res.status(200).json(nearbyVehicles);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});


app.get('/emergency', async (req, res) => {
  try {
    const emergencyVehicles = await Vehicle.find({ title: 'emergency' });

    res.status(200).json(emergencyVehicles);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
