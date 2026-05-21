import { useState } from 'react';

type PrototypeGameState = {
  resources: number;
  scanSector: () => void;
  upgradeShip: () => void;
};

export function usePrototypeGameState(): PrototypeGameState {
  const [resources, setResources] = useState(12);

  function scanSector() {
    setResources((current) => current + 3);
  }

  function upgradeShip() {
    setResources((current) => Math.max(0, current - 5));
  }

  return {
    resources,
    scanSector,
    upgradeShip,
  };
}
