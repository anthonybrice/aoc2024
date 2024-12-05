from collections import defaultdict, deque

def parse_file(file_path):
    with open(file_path, 'r') as file:
        sections = file.read().split('\n\n')

        # Parse pairs from the first section
        pairs = [tuple(map(int, line.split('|'))) for line in sections[0].splitlines()]

        # Parse sequences from the second section
        sequences = [list(map(int, line.split(','))) for line in sections[1].splitlines()]

    return pairs, sequences

def filter_pairs_for_sequence(pairs, sequence):
    sequence_set = set(sequence)
    return [(x, y) for x, y in pairs if x in sequence_set and y in sequence_set]

def topological_sort(pairs):
    # Step 1: Build the graph
    graph = defaultdict(list)
    in_degree = defaultdict(int)
    nodes = set()

    for x, y in pairs:
        graph[x].append(y)
        in_degree[y] += 1
        in_degree.setdefault(x, 0)  # Ensure all nodes are in in-degree map
        nodes.update([x, y])

    # Step 2: Perform Kahn's Algorithm
    queue = deque([node for node in nodes if in_degree[node] == 0])
    topological_order = []

    while queue:
        current = queue.popleft()
        topological_order.append(current)

        for neighbor in graph[current]:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)

    # Check if there's a cycle
    if len(topological_order) != len(nodes):
        raise ValueError("The graph contains a cycle, ordering is not possible.")

    return topological_order

def verify_and_correct_sequences(pairs, sequences):
    results = []
    total_sum = 0
    corrected_sum = 0

    for sequence in sequences:
        # Step 1: Filter pairs for the current sequence
        filtered_pairs = filter_pairs_for_sequence(pairs, sequence)

        # Step 2: Generate topological order for the current sequence
        try:
            ordering = topological_sort(filtered_pairs)
        except ValueError:
            # If there's a cycle, the sequence cannot be validated
            results.append((sequence, False, None, None))
            continue

        # Step 3: Create a position map for the ordering
        position = {value: idx for idx, value in enumerate(ordering)}

        # Step 4: Check if the sequence matches the order
        is_ordered = all(position[sequence[i]] <= position[sequence[i+1]] for i in range(len(sequence) - 1))

        # Step 5: Calculate the middle number
        middle_number = None
        corrected_middle_number = None
        if is_ordered:
            middle_index = len(sequence) // 2
            middle_number = sequence[middle_index]
            total_sum += middle_number
        else:
            # Correct the sequence by reordering it according to the topological sort
            corrected_sequence = sorted(sequence, key=lambda x: position[x])
            corrected_middle_index = len(corrected_sequence) // 2
            corrected_middle_number = corrected_sequence[corrected_middle_index]
            corrected_sum += corrected_middle_number

        results.append((sequence, is_ordered, middle_number, corrected_middle_number))

    return total_sum, corrected_sum, results

# Example Usage
file_path = 'in/day5.txt'  # Replace with your file name
pairs, sequences = parse_file(file_path)
total_sum, corrected_sum, results = verify_and_correct_sequences(pairs, sequences)

# Print Results
print(f"Total Sum of Middle Numbers (Correctly Ordered): {total_sum}")
print(f"Total Sum of Middle Numbers (Corrected Sequences): {corrected_sum}")
