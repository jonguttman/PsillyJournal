import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';

export interface ActivityTag {
  id: string;
  emoji: string;
  label: string;
}

export const ACTIVITY_TAGS: ActivityTag[] = [
  { id: 'moving', emoji: '🚶', label: 'Moving' },
  { id: 'still', emoji: '🧘', label: 'Still' },
  { id: 'social', emoji: '👥', label: 'Social' },
  { id: 'creating', emoji: '🎨', label: 'Creating' },
  { id: 'thinking', emoji: '🤔', label: 'Thinking' },
  { id: 'nature', emoji: '🌳', label: 'Nature' },
  { id: 'home', emoji: '🏠', label: 'Home' },
  { id: 'work', emoji: '💼', label: 'Work' },
];

interface ActivityTagSelectorProps {
  selectedTags: string[];
  onTagsChange: (tags: string[]) => void;
}

export function ActivityTagSelector({ selectedTags, onTagsChange }: ActivityTagSelectorProps) {
  const toggleTag = (tagId: string) => {
    if (selectedTags.includes(tagId)) {
      // Deselect
      onTagsChange(selectedTags.filter(id => id !== tagId));
    } else {
      // Select
      onTagsChange([...selectedTags, tagId]);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.tagsGrid}>
        {ACTIVITY_TAGS.map((tag) => {
          const isSelected = selectedTags.includes(tag.id);
          return (
            <TouchableOpacity
              key={tag.id}
              style={[styles.tag, isSelected && styles.tagSelected]}
              onPress={() => toggleTag(tag.id)}
            >
              <Text style={styles.emoji}>{tag.emoji}</Text>
              <Text style={[styles.label, isSelected && styles.labelSelected]}>
                {tag.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: 16,
  },
  tagsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  tag: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#18181b',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#27272a',
    gap: 6,
  },
  tagSelected: {
    backgroundColor: '#5b21b6',
    borderColor: '#5b21b6',
  },
  emoji: {
    fontSize: 16,
  },
  label: {
    color: '#a1a1aa',
    fontSize: 14,
    fontWeight: '500',
  },
  labelSelected: {
    color: '#ffffff',
  },
});
