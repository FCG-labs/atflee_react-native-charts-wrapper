import React, {Component} from 'react';
import { UIManager, findNodeHandle} from 'react-native';


function getCommand(extendedChart, commandName) {
  if (global?.nativeFabricUIManager) {
    return commandName;
  }

  return UIManager.getViewManagerConfig(extendedChart.getNativeComponentName()).Commands[commandName];
}

export default function HighlightEnhancer(Chart) {
  return class HighlightExtended extends Chart {
    highlights(config) {
      UIManager.dispatchViewManagerCommand(
        findNodeHandle(this.getNativeComponentRef()),
        getCommand(this, 'highlights'),
        [config]
      );
    }
  }
}