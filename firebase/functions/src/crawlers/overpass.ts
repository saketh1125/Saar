/**
 * OSM Overpass Crawler — fetches POI data from OpenStreetMap for Varanasi.
 *
 * Runs weekly to refresh the POI database with temples, ghats, food spots, etc.
 * Query covers a ~15km radius around Varanasi city center.
 */
import axios from 'axios';

const OVERPASS_URL = 'https://overpass-api.de/api/interpreter';

interface OverpassNode {
  id: string;
  lat: number;
  lon: number;
  tags: Record<string, string>;
}

interface OverpassResponse {
  elements: OverpassNode[];
}

/**
 * Fetch POIs from OSM Overpass API for Varanasi.
 * Returns temples, ghats, food spots, safety nodes, water/toilet facilities.
 */
export async function fetchOverpassPois(): Promise<OverpassNode[]> {
  const query = `
[out:json][timeout:60];
area["name"="Varanasi"]["admin_level"="6"]->.varanasi;
(
  node["amenity"~"place_of_worship|restaurant|cafe|hospital|police|atm|drinking_water|toilets"](area.varanasi);
  node["tourism"~"attraction|viewpoint|museum"](area.varanasi);
  node["historic"](area.varanasi);
  way["highway"="pedestrian"](area.varanasi);
  node["name"~"ghat|Ghat"](area.varanasi);
);
out body;
>;
out skel qt;
`;

  try {
    const response = await axios.post(
      OVERPASS_URL,
      `data=${encodeURIComponent(query)}`,
      {
        timeout: 60000,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      }
    );

    const data: OverpassResponse = response.data;
    return data.elements.map((el) => ({
      id: `osm_${el.id}`,
      lat: el.lat,
      lon: el.lon,
      tags: el.tags || {},
    }));
  } catch (e) {
    console.error('Overpass API fetch failed:', e);
    return [];
  }
}
